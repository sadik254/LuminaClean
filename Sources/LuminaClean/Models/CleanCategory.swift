import Foundation
import SwiftUI

public enum CleanCategory: String, CaseIterable, Identifiable, Sendable {
    case systemJunk = "System Junk"
    case developerCache = "Developer Cache"
    case appLeftovers = "App Leftovers"
    case trash = "Trash Can"

    public var id: String { rawValue }

    public var title: String { rawValue }

    public var iconName: String {
        switch self {
        case .systemJunk:
            return "internaldrive"
        case .developerCache:
            return "hammer.fill"
        case .appLeftovers:
            return "trash.slash.fill"
        case .trash:
            return "trash.fill"
        }
    }

    public var accentColor: Color {
        switch self {
        case .systemJunk:
            return .blue
        case .developerCache:
            return .orange
        case .appLeftovers:
            return .purple
        case .trash:
            return .red
        }
    }

    public var description: String {
        switch self {
        case .systemJunk:
            return "Temporary application caches, system logs, and crash reports."
        case .developerCache:
            return "Xcode DerivedData, simulator caches, archives, and build artifacts."
        case .appLeftovers:
            return "Residual configuration and data folders left by uninstalled applications."
        case .trash:
            return "Files and folders currently sitting in your macOS Trash."
        }
    }
}
