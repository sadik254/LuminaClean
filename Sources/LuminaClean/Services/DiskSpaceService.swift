import Foundation

public final class DiskSpaceService: Sendable {
    public static let shared = DiskSpaceService()

    public init() {}

    public func fetchDiskInfo() -> DiskInfo {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        do {
            let values = try homeURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeAvailableCapacityKey
            ])

            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = values.volumeAvailableCapacityForImportantUsage ?? Int64(values.volumeAvailableCapacity ?? 0)

            return DiskInfo(totalBytes: total, freeBytes: free)
        } catch {
            return DiskInfo(totalBytes: 0, freeBytes: 0)
        }
    }
}
