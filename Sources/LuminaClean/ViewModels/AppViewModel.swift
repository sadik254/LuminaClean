import Foundation
import SwiftUI
import Observation

public enum NavigationTab: String, CaseIterable, Identifiable, Sendable {
    case dashboard = "Overview"
    case systemJunk = "System Junk"
    case developerCache = "Developer Cache"
    case appLeftovers = "App Leftovers"
    case trash = "Trash Can"
    case settings = "Settings"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.50percent"
        case .systemJunk: return "internaldrive"
        case .developerCache: return "hammer.fill"
        case .appLeftovers: return "trash.slash.fill"
        case .trash: return "trash.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public enum ScanState: Equatable, Sendable {
    case idle
    case scanning(current: String, progress: Double)
    case scanned
    case cleaning(current: String, progress: Double)
    case finished(freedBytes: Int64)
}

@Observable
@MainActor
public final class AppViewModel {
    public var selectedTab: NavigationTab = .dashboard
    public var scanState: ScanState = .idle
    public var items: [JunkItem] = []
    public var diskInfo: DiskInfo = DiskInfo()
    public var statusMessage: String = "Ready to scan"
    public var scanProgress: Double = 0.0
    public var lastCleanedBytes: Int64 = 0
    public var showCleanConfirmation: Bool = false

    public init() {
        refreshDiskInfo()
    }

    public func refreshDiskInfo() {
        self.diskInfo = DiskSpaceService.shared.fetchDiskInfo()
    }

    public var totalCleanableBytes: Int64 {
        items.reduce(0) { $0 + $1.sizeBytes }
    }

    public var selectedCleanableBytes: Int64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }

    public func items(for category: CleanCategory) -> [JunkItem] {
        items.filter { $0.category == category }
    }

    public func categorySize(for category: CleanCategory) -> Int64 {
        items(for: category).reduce(0) { $0 + $1.sizeBytes }
    }

    public func categorySelectedSize(for category: CleanCategory) -> Int64 {
        items(for: category).filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }

    // MARK: - Actions
    public func startScan() {
        guard scanState == .idle || scanState == .scanned || (ifCaseFinished()) else { return }

        scanState = .scanning(current: "Initializing...", progress: 0.0)
        statusMessage = "Scanning disk caches..."
        scanProgress = 0.0
        items = []

        Task { [self] in
            let scanned = await ScannerEngine.shared.scanAll { [weak self] message, progress in
                Task { @MainActor in
                    self?.updateScanProgress(message: message, progress: progress)
                }
            }

            self.items = scanned
            self.scanState = .scanned
            self.statusMessage = "Scan completed. Found \(ByteCountFormatter.string(fromByteCount: self.totalCleanableBytes, countStyle: .file)) of cleanable junk."
            self.refreshDiskInfo()
        }
    }

    public func cleanSelected() {
        let toClean = items.filter(\.isSelected)
        guard !toClean.isEmpty else { return }

        scanState = .cleaning(current: "Starting cleanup...", progress: 0.0)
        statusMessage = "Cleaning selected items..."

        Task { [self] in
            let (freed, _) = await CleaningEngine.shared.clean(items: toClean) { [weak self] current, freedSoFar, progress in
                Task { @MainActor in
                    self?.updateCleanProgress(current: current, progress: progress)
                }
            }

            self.lastCleanedBytes = freed
            self.scanState = .finished(freedBytes: freed)
            self.statusMessage = "Successfully freed \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))!"
            self.refreshDiskInfo()

            // Remove cleaned items from list
            self.items.removeAll { $0.isSelected }
        }
    }

    private func updateScanProgress(message: String, progress: Double) {
        self.statusMessage = message
        self.scanProgress = progress
        self.scanState = .scanning(current: message, progress: progress)
    }

    private func updateCleanProgress(current: String, progress: Double) {
        self.statusMessage = "Cleaning \(current)..."
        self.scanProgress = progress
        self.scanState = .cleaning(current: current, progress: progress)
    }

    public func toggleItemSelection(id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isSelected.toggle()
        }
    }

    public func setAllSelected(in category: CleanCategory, selected: Bool) {
        for index in items.indices where items[index].category == category {
            items[index].isSelected = selected
        }
    }

    private func ifCaseFinished() -> Bool {
        if case .finished = scanState { return true }
        return false
    }
}
