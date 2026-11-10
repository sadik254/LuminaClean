import Foundation

public final class ScannerEngine: Sendable {
    public static let shared = ScannerEngine()

    public init() {}

    public typealias ProgressHandler = @Sendable (String, Double) -> Void

    public func scanAll(onProgress: ProgressHandler? = nil) async -> [JunkItem] {
        var results: [JunkItem] = []

        // 1. Scan Developer Caches (Highest ROI for developers)
        onProgress?("Scanning Developer caches...", 0.1)
        results.append(contentsOf: await scanDeveloperCaches())

        // 2. Scan User Caches & Logs
        onProgress?("Scanning Application caches & logs...", 0.35)
        results.append(contentsOf: await scanCachesAndLogs())

        // 3. Scan Trash
        onProgress?("Scanning Trash Can...", 0.65)
        if let trashItem = await scanTrash() {
            results.append(trashItem)
        }

        // 4. Scan App Leftovers
        onProgress?("Scanning App leftovers...", 0.85)
        results.append(contentsOf: await scanAppLeftovers())

        onProgress?("Scan complete", 1.0)
        return results
    }

    // MARK: - Developer Caches
    public func scanDeveloperCaches() async -> [JunkItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [JunkItem] = []

        let targets: [(name: String, path: URL, desc: String, icon: String)] = [
            ("Xcode DerivedData", home.appendingPathComponent("Library/Developer/Xcode/DerivedData"), "Intermediate build products, module caches, and index files.", "hammer.fill"),
            ("Xcode Archives", home.appendingPathComponent("Library/Developer/Xcode/Archives"), "Historical app build archives and dSYM files.", "archivebox.fill"),
            ("Xcode iOS DeviceSupport", home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport"), "Symbol files for older physical iOS devices.", "iphone"),
            ("CocoaPods Cache", home.appendingPathComponent("Library/Caches/CocoaPods"), "Downloaded pod repositories and frameworks.", "shippingbox.fill"),
            ("CocoaPods Root Cache", home.appendingPathComponent(".cocoapods/cache"), "Global CocoaPods specs and tarballs.", "shippingbox.fill"),
            ("Homebrew Cache", home.appendingPathComponent("Library/Caches/Homebrew"), "Downloaded bottle archives and git repositories.", "mug.fill"),
            ("npm Cache", home.appendingPathComponent(".npm/_cacache"), "Cached node packages and registry data.", "cube.box.fill"),
            ("Gradle Cache", home.appendingPathComponent(".gradle/caches"), "Downloaded dependencies and daemon build caches.", "gearshape.2.fill")
        ]

        for target in targets {
            if FileManager.default.fileExists(atPath: target.path.path) {
                let (size, count) = calculateSizeAndCount(of: target.path)
                if size > 1_000_000 { // Only show if > 1 MB
                    items.append(JunkItem(
                        name: target.name,
                        category: .developerCache,
                        url: target.path,
                        sizeBytes: size,
                        itemCount: count,
                        isSelected: true,
                        isSafe: true,
                        iconName: target.icon,
                        details: target.desc
                    ))
                }
            }
        }

        return items
    }

    // MARK: - User Caches & Logs
    public func scanCachesAndLogs() async -> [JunkItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [JunkItem] = []

        let cachesDir = home.appendingPathComponent("Library/Caches")
        let logsDir = home.appendingPathComponent("Library/Logs")

        // Known heavy cache culprits to single out
        let specificCaches: [(id: String, name: String, desc: String, icon: String)] = [
            ("com.spotify.client", "Spotify Cache", "Downloaded music streaming cache and offline database.", "music.note"),
            ("Google/Chrome", "Google Chrome Cache", "Web browsing cache, media, and temporary assets.", "globe"),
            ("com.google.Chrome", "Google Chrome Cache", "Web browsing cache, media, and temporary assets.", "globe"),
            ("com.brave.Browser", "Brave Browser Cache", "Web browsing cache, media, and temporary assets.", "shield.fill"),
            ("com.apple.Safari", "Safari Cache", "Temporary website files, previews, and icons.", "safari"),
            ("com.tinyspeck.slackmacgap", "Slack Cache", "Cached channel messages, previews, and avatars.", "message.fill"),
            ("com.hnc.Discord", "Discord Cache", "Voice chat logs, server media, and avatars.", "bubble.left.and.bubble.right.fill"),
            ("com.microsoft.VSCode", "VS Code Cache", "Workspace storage, extensions cache, and logs.", "chevron.left.forwardslash.chevron.right")
        ]

        var processedCachePaths = Set<String>()

        for target in specificCaches {
            let path = cachesDir.appendingPathComponent(target.id)
            if FileManager.default.fileExists(atPath: path.path) {
                processedCachePaths.insert(path.path)
                let (size, count) = calculateSizeAndCount(of: path)
                if size > 10_000_000 { // > 10 MB
                    items.append(JunkItem(
                        name: target.name,
                        category: .systemJunk,
                        url: path,
                        sizeBytes: size,
                        itemCount: count,
                        isSelected: true,
                        isSafe: true,
                        iconName: target.icon,
                        details: target.desc
                    ))
                }
            }
        }

        // Scan remainder of ~/Library/Caches
        if let subdirs = try? FileManager.default.contentsOfDirectory(at: cachesDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            var miscCacheSize: Int64 = 0
            var miscCacheCount = 0

            for subdir in subdirs {
                if !processedCachePaths.contains(subdir.path) {
                    let (size, count) = calculateSizeAndCount(of: subdir)
                    if size > 50_000_000 { // Individual app cache > 50 MB
                        items.append(JunkItem(
                            name: "\(subdir.lastPathComponent) Cache",
                            category: .systemJunk,
                            url: subdir,
                            sizeBytes: size,
                            itemCount: count,
                            isSelected: true,
                            isSafe: true,
                            iconName: "app.badge",
                            details: "Application temporary storage and cached files."
                        ))
                    } else {
                        miscCacheSize += size
                        miscCacheCount += count
                    }
                }
            }

            if miscCacheSize > 5_000_000 {
                items.append(JunkItem(
                    name: "Other Application Caches",
                    category: .systemJunk,
                    url: cachesDir,
                    sizeBytes: miscCacheSize,
                    itemCount: miscCacheCount,
                    isSelected: true,
                    isSafe: true,
                    iconName: "shippingbox",
                    details: "Temporary cache files from various installed applications."
                ))
            }
        }

        // Scan ~/Library/Logs
        if FileManager.default.fileExists(atPath: logsDir.path) {
            let (logSize, logCount) = calculateSizeAndCount(of: logsDir)
            if logSize > 1_000_000 {
                items.append(JunkItem(
                    name: "User & Application Logs",
                    category: .systemJunk,
                    url: logsDir,
                    sizeBytes: logSize,
                    itemCount: logCount,
                    isSelected: true,
                    isSafe: true,
                    iconName: "doc.text.fill",
                    details: "Historical error logs, debug logs, and diagnostic traces."
                ))
            }
        }

        return items
    }

    // MARK: - Trash Can
    public func scanTrash() async -> JunkItem? {
        let trashURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        guard FileManager.default.fileExists(atPath: trashURL.path) else { return nil }

        let (size, count) = calculateSizeAndCount(of: trashURL)
        guard size > 0 else { return nil }

        return JunkItem(
            name: "macOS Trash Can",
            category: .trash,
            url: trashURL,
            sizeBytes: size,
            itemCount: count,
            isSelected: true,
            isSafe: true,
            iconName: "trash.fill",
            details: "Files and folders discarded by the user waiting to be purged."
        )
    }

    // MARK: - App Leftovers (Uninstalled App Residuals)
    public func scanAppLeftovers() async -> [JunkItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let appSupport = home.appendingPathComponent("Library/Application Support")
        guard let folders = try? FileManager.default.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return []
        }

        // Build list of installed app names
        let installedAppNames = fetchInstalledAppNames()
        var leftovers: [JunkItem] = []

        // Whitelisted Apple system folders that should never be flagged
        let systemFolders: Set<String> = [
            "Apple", "CrashReporter", "Dock", "AddressBook", "iCloud",
            "com.apple.sharedfilelist", "SyncServices", "Quick Look", "CallHistoryDB",
            "FaceTime", "Knowledge", "DiskImages", "MobileSync", "Google", "Mozilla"
        ]

        for folder in folders {
            let folderName = folder.lastPathComponent
            if systemFolders.contains(folderName) || folderName.hasPrefix("com.apple.") {
                continue
            }

            // If the folder name doesn't match any installed app
            let isAppInstalled = installedAppNames.contains { appName in
                appName.localizedCaseInsensitiveContains(folderName) ||
                folderName.localizedCaseInsensitiveContains(appName)
            }

            if !isAppInstalled {
                let (size, count) = calculateSizeAndCount(of: folder)
                if size > 5_000_000 { // > 5 MB
                    leftovers.append(JunkItem(
                        name: "\(folderName) Leftover",
                        category: .appLeftovers,
                        url: folder,
                        sizeBytes: size,
                        itemCount: count,
                        isSelected: false, // Default to unchecked for safety
                        isSafe: true,
                        iconName: "trash.slash",
                        details: "Residual support folder for an app that may have been uninstalled."
                    ))
                }
            }
        }

        return leftovers
    }

    // MARK: - Helper Methods
    private func fetchInstalledAppNames() -> Set<String> {
        var names = Set<String>()
        let searchDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        for dir in searchDirs {
            if let apps = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for app in apps where app.pathExtension == "app" {
                    names.insert(app.deletingPathExtension().lastPathComponent)
                }
            }
        }
        return names
    }

    public func calculateSizeAndCount(of url: URL) -> (Int64, Int) {
        var totalSize: Int64 = 0
        var totalCount = 0

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
            return (0, 0)
        }

        if !isDir.boolValue {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                return (size, 1)
            }
            return (0, 1)
        }

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return (0, 0)
        }

        for case let fileURL as URL in enumerator {
            totalCount += 1
            if let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey]) {
                let size = values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? values.fileSize ?? 0
                totalSize += Int64(size)
            }
        }

        return (totalSize, totalCount)
    }
}
