import SwiftUI

public struct ContentView: View {
    @State private var viewModel = AppViewModel()

    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            detailContent
                .navigationTitle(viewModel.selectedTab.rawValue)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            viewModel.startScan()
                        } label: {
                            Label("Scan", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .help("Scan Mac for Junk")
                    }
                }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch viewModel.selectedTab {
        case .dashboard:
            DashboardView(viewModel: viewModel)
        case .systemJunk:
            CategoryDetailView(category: .systemJunk, viewModel: viewModel)
        case .developerCache:
            CategoryDetailView(category: .developerCache, viewModel: viewModel)
        case .appLeftovers:
            CategoryDetailView(category: .appLeftovers, viewModel: viewModel)
        case .trash:
            CategoryDetailView(category: .trash, viewModel: viewModel)
        case .settings:
            SettingsView()
        }
    }
}
