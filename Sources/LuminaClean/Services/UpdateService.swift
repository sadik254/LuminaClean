import Foundation
import AppKit
import Observation

public struct GitHubRelease: Codable, Sendable, Equatable {
    public let tagName: String
    public let name: String
    public let body: String?
    public let htmlUrl: String
    public let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case assets
    }

    public var cleanVersion: String {
        tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
    }
}

public struct GitHubAsset: Codable, Sendable, Equatable {
    public let name: String
    public let browserDownloadUrl: String
    public let size: Int64

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
    }
}

public enum UpdateStatus: Equatable, Sendable {
    case idle
    case checking
    case upToDate(currentVersion: String)
    case available(version: String, release: GitHubRelease)
    case downloading(progress: Double)
    case installing
    case error(message: String)
}

@Observable
@MainActor
public final class UpdateService {
    public static let shared = UpdateService()

    public var status: UpdateStatus = .idle
    public var currentVersion: String {
        if let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !ver.isEmpty {
            return ver
        }
        return "1.0.0"
    }

    public var isCheckingOrUpdating: Bool {
        switch status {
        case .checking, .downloading, .installing:
            return true
        default:
            return false
        }
    }

    public init() {}

    // MARK: - Check For Updates
    public func checkForUpdates() async {
        status = .checking

        let repoURL = URL(string: "https://api.github.com/repos/sadik254/LuminaClean/releases/latest")!
        var request = URLRequest(url: repoURL)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("LuminaClean-macOS", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                status = .error(message: "Invalid server response.")
                return
            }

            if httpResponse.statusCode == 404 {
                status = .upToDate(currentVersion: currentVersion)
                return
            }

            guard httpResponse.statusCode == 200 else {
                status = .error(message: "GitHub API error (\(httpResponse.statusCode)). Please try again later.")
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let remoteVersion = release.cleanVersion

            if Self.isVersion(remoteVersion, newerThan: currentVersion) {
                status = .available(version: remoteVersion, release: release)
            } else {
                status = .upToDate(currentVersion: currentVersion)
            }
        } catch {
            status = .error(message: "Unable to check for updates: \(error.localizedDescription)")
        }
    }

    // MARK: - Download & Apply Update
    public func downloadAndInstall(release: GitHubRelease) async {
        // Find .zip asset
        guard let zipAsset = release.assets.first(where: { $0.name.hasSuffix(".zip") }) else {
            status = .error(message: "No compatible update zip archive found in release assets.")
            return
        }

        guard let downloadURL = URL(string: zipAsset.browserDownloadUrl) else {
            status = .error(message: "Invalid download link.")
            return
        }

        status = .downloading(progress: 0.0)

        do {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("LuminaCleanUpdate_\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            let zipFileDestination = tempDir.appendingPathComponent(zipAsset.name)

            // Download with progress tracking
            var req = URLRequest(url: downloadURL)
            req.setValue("LuminaClean-macOS", forHTTPHeaderField: "User-Agent")

            let (asyncBytes, response) = try await URLSession.shared.bytes(for: req)
            let totalExpected = response.expectedContentLength > 0 ? Double(response.expectedContentLength) : Double(zipAsset.size)

            var fileData = Data()
            if totalExpected > 0 {
                fileData.reserveCapacity(Int(totalExpected))
            }

            var lastReportedProgress: Double = 0.0
            for try await byte in asyncBytes {
                fileData.append(byte)
                if totalExpected > 0 {
                    let current = Double(fileData.count) / totalExpected
                    if current - lastReportedProgress >= 0.05 || current >= 0.99 {
                        lastReportedProgress = current
                        self.status = .downloading(progress: min(current, 1.0))
                    }
                }
            }

            try fileData.write(to: zipFileDestination)

            // Extract archive
            self.status = .installing

            let extractDir = tempDir.appendingPathComponent("Extracted")
            try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

            let dittoProcess = Process()
            dittoProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            dittoProcess.arguments = ["-x", "-k", zipFileDestination.path, extractDir.path]
            try dittoProcess.run()
            dittoProcess.waitUntilExit()

            guard dittoProcess.terminationStatus == 0 else {
                status = .error(message: "Failed to extract update package.")
                return
            }

            // Find LuminaClean.app
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: extractDir, includingPropertiesForKeys: nil)
            guard let newAppURL = contents.first(where: { $0.lastPathComponent == "LuminaClean.app" }) else {
                status = .error(message: "Updated application bundle not found in archive.")
                return
            }

            // Determine target installation path
            let currentBundleURL = Bundle.main.bundleURL
            let targetAppURL: URL
            if currentBundleURL.pathExtension == "app" {
                targetAppURL = currentBundleURL
            } else {
                // If run from command line / Xcode, fallback to /Applications/LuminaClean.app
                targetAppURL = URL(fileURLWithPath: "/Applications/LuminaClean.app")
            }

            // Execute restart script
            try launchRestartHelper(newAppURL: newAppURL, targetAppURL: targetAppURL, cleanupDir: tempDir)

        } catch {
            status = .error(message: "Update installation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Restart Helper
    private func launchRestartHelper(newAppURL: URL, targetAppURL: URL, cleanupDir: URL) throws {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let scriptURL = cleanupDir.appendingPathComponent("update_restart.sh")

        let script = """
        #!/bin/bash
        # Wait for the current LuminaClean instance to quit
        while kill -0 \(currentPID) 2>/dev/null; do
            sleep 0.2
        done

        # Replace target application bundle
        rm -rf "\(targetAppURL.path)"
        cp -R "\(newAppURL.path)" "\(targetAppURL.path)"

        # Re-launch updated LuminaClean
        open "\(targetAppURL.path)"

        # Cleanup update working files
        sleep 1
        rm -rf "\(cleanupDir.path)"
        """

        try script.write(to: scriptURL, atomically: true, encoding: .utf8)

        // Make executable
        let chmod = Process()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments = ["+x", scriptURL.path]
        try chmod.run()
        chmod.waitUntilExit()

        // Run detached bash script
        let runner = Process()
        runner.executableURL = URL(fileURLWithPath: "/bin/bash")
        runner.arguments = [scriptURL.path]
        try runner.run()

        // Terminate running application
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.terminate(nil)
        }
    }

    // MARK: - Version Comparison Utility
    public static func isVersion(_ remote: String, newerThan local: String) -> Bool {
        let cleanRemote = remote.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
        let cleanLocal = local.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))

        let rParts = cleanRemote.split(separator: ".").compactMap { Int($0) }
        let lParts = cleanLocal.split(separator: ".").compactMap { Int($0) }

        let maxLen = max(rParts.count, lParts.count)
        for i in 0..<maxLen {
            let r = i < rParts.count ? rParts[i] : 0
            let l = i < lParts.count ? lParts[i] : 0
            if r > l { return true }
            if r < l { return false }
        }
        return false
    }
}
