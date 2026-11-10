import Foundation

public struct JunkItem: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let category: CleanCategory
    public let url: URL
    public let sizeBytes: Int64
    public let itemCount: Int
    public var isSelected: Bool
    public let isSafe: Bool
    public let iconName: String
    public let details: String

    public init(
        id: UUID = UUID(),
        name: String,
        category: CleanCategory,
        url: URL,
        sizeBytes: Int64,
        itemCount: Int = 1,
        isSelected: Bool = true,
        isSafe: Bool = true,
        iconName: String = "folder.fill",
        details: String = ""
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.url = url
        self.sizeBytes = sizeBytes
        self.itemCount = itemCount
        self.isSelected = isSelected
        self.isSafe = isSafe
        self.iconName = iconName
        self.details = details
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    public var displayPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if url.path.hasPrefix(home) {
            return "~" + url.path.dropFirst(home.count)
        }
        return url.path
    }
}
