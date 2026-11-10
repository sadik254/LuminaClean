import SwiftUI

public struct SidebarView: View {
    @Bindable var viewModel: AppViewModel

    public var body: some View {
        VStack(spacing: 0) {
            // App Branding Header
            HStack(spacing: 12) {
                ZStack {
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("LuminaClean")
                        .font(.system(size: 15, weight: .bold))
                    Text("Mac Maintenance")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            // Navigation List
            List(selection: $viewModel.selectedTab) {
                Section("Cleaning Modules") {
                    NavigationLink(value: NavigationTab.dashboard) {
                        Label {
                            Text(NavigationTab.dashboard.rawValue)
                        } icon: {
                            Image(systemName: NavigationTab.dashboard.iconName)
                                .foregroundStyle(.blue)
                        }
                    }

                    ForEach([CleanCategory.systemJunk, .developerCache, .appLeftovers, .trash], id: \.self) { cat in
                        let tab = tabFor(category: cat)
                        NavigationLink(value: tab) {
                            HStack {
                                Label {
                                    Text(cat.title)
                                } icon: {
                                    Image(systemName: cat.iconName)
                                        .foregroundStyle(cat.accentColor)
                                }

                                Spacer()

                                let size = viewModel.categorySize(for: cat)
                                if size > 0 {
                                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(cat.accentColor.opacity(0.15))
                                        .foregroundStyle(cat.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                Section("Preferences") {
                    NavigationLink(value: NavigationTab.settings) {
                        Label(NavigationTab.settings.rawValue, systemImage: NavigationTab.settings.iconName)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Storage Meter at Bottom
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Macintosh HD")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(viewModel.diskInfo.formattedFree) Free")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: viewModel.diskInfo.usedPercentage)
                    .tint(.blue)
                    .scaleEffect(x: 1, y: 0.8, anchor: .center)

                Text("\(viewModel.diskInfo.formattedUsed) used of \(viewModel.diskInfo.formattedTotal)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(.ultraThinMaterial)
        }
    }

    private func tabFor(category: CleanCategory) -> NavigationTab {
        switch category {
        case .systemJunk: return .systemJunk
        case .developerCache: return .developerCache
        case .appLeftovers: return .appLeftovers
        case .trash: return .trash
        }
    }
}
