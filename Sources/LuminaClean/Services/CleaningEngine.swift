import Foundation

public final class CleaningEngine: Sendable {
    public static let shared = CleaningEngine()

    public init() {}

    public typealias CleanProgressHandler = @Sendable (String, Int64, Double) -> Void

    public func clean(items: [JunkItem], onProgress: CleanProgressHandler? = nil) async -> (Int64, [String]) {
        var totalFreed: Int64 = 0
        var errors: [String] = []

        let totalItems = Double(items.count)
        for (index, item) in items.enumerated() {
            guard item.isSelected else { continue }

            let progressFraction = totalItems > 0 ? Double(index) / totalItems : 0
            onProgress?(item.name, totalFreed, progressFraction)

            let (freed, error) = cleanItem(item)
            totalFreed += freed
            if let error = error {
                errors.append("\(item.name): \(error)")
            }
        }

        onProgress?("Cleaning finished", totalFreed, 1.0)
        return (totalFreed, errors)
    }

    private func cleanItem(_ item: JunkItem) -> (Int64, String?) {
        let fm = FileManager.default

        // For root folders like ~/Library/Caches or ~/Library/Logs or ~/.Trash:
        // We delete their contents, NOT the parent folder itself.
        let protectedParents = Set([
            fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches").path,
            fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs").path,
            fm.homeDirectoryForCurrentUser.appendingPathComponent(".Trash").path
        ])

        if protectedParents.contains(item.url.path) {
            guard let contents = try? fm.contentsOfDirectory(at: item.url, includingPropertiesForKeys: nil) else {
                return (0, "Could not read contents")
            }

            var freed: Int64 = 0
            for child in contents {
                let (childSize, _) = ScannerEngine.shared.calculateSizeAndCount(of: child)
                do {
                    try fm.removeItem(at: child)
                    freed += childSize
                } catch {
                    // Skip files locked by running apps
                }
            }
            return (freed, nil)
        }

        // For specific target subfolders (e.g. DerivedData, Spotify Cache, App Leftovers):
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: item.url.path, isDirectory: &isDir) {
            do {
                try fm.removeItem(at: item.url)
                return (item.sizeBytes, nil)
            } catch {
                return (0, error.localizedDescription)
            }
        }

        return (0, nil)
    }
}
