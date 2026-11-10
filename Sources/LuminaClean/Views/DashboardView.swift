import SwiftUI

public struct DashboardView: View {
    @Bindable var viewModel: AppViewModel

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Card
                heroSection

                // Scanning Progress Bar (When Active)
                if case .scanning = viewModel.scanState {
                    scanningProgressCard
                } else if case .cleaning = viewModel.scanState {
                    cleaningProgressCard
                }

                // 4 Category Quick Cards
                categoryGrid

                Spacer()
            }
            .padding(24)
        }
        .confirmationDialog(
            "Clean Selected Items?",
            isPresented: $viewModel.showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clean \(ByteCountFormatter.string(fromByteCount: viewModel.selectedCleanableBytes, countStyle: .file))", role: .destructive) {
                viewModel.cleanSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Selected junk files, caches, and build artifacts will be removed. This cannot be undone.")
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )

            HStack(spacing: 28) {
                // Gauge Ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: viewModel.diskInfo.usedPercentage)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: viewModel.diskInfo.usedPercentage)

                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.diskInfo.usedPercentage * 100))%")
                            .font(.system(size: 24, weight: .bold))
                        Text("Used")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                // Text & Action
                VStack(alignment: .leading, spacing: 10) {
                    if viewModel.totalCleanableBytes > 0 {
                        Text("Found \(ByteCountFormatter.string(fromByteCount: viewModel.totalCleanableBytes, countStyle: .file)) of cleanable files")
                            .font(.system(size: 20, weight: .bold))
                        Text("\(ByteCountFormatter.string(fromByteCount: viewModel.selectedCleanableBytes, countStyle: .file)) currently selected for cleanup.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    } else if case .finished(let freed) = viewModel.scanState {
                        Text("Clean Complete!")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.green)
                        Text("Successfully recovered \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file)) of free space.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Optimize & Clean Your Mac")
                            .font(.system(size: 20, weight: .bold))
                        Text("Reclaim gigabytes of hidden caches, logs, developer bloat, and app leftovers.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        if viewModel.selectedCleanableBytes > 0 {
                            Button {
                                viewModel.showCleanConfirmation = true
                            } label: {
                                Label("Clean Selected Files", systemImage: "sparkles")
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .controlSize(.large)
                        }

                        Button {
                            viewModel.startScan()
                        } label: {
                            Label(viewModel.items.isEmpty ? "Start Deep Scan" : "Rescan Mac", systemImage: "arrow.triangle.2.circlepath")
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }

                Spacer()
            }
            .padding(24)
        }
    }

    // MARK: - Scanning Progress Card
    private var scanningProgressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text(viewModel.statusMessage)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text("\(Int(viewModel.scanProgress * 100))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: viewModel.scanProgress)
                .tint(.blue)
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Cleaning Progress Card
    private var cleaningProgressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text(viewModel.statusMessage)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            ProgressView(value: viewModel.scanProgress)
                .tint(.green)
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Category Grid
    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(CleanCategory.allCases) { cat in
                categoryCard(for: cat)
            }
        }
    }

    private func categoryCard(for category: CleanCategory) -> some View {
        let size = viewModel.categorySize(for: category)
        let items = viewModel.items(for: category)

        return Button {
            navigateTo(category: category)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(category.accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: category.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(category.accentColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(category.description)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Divider()

                HStack {
                    if size > 0 {
                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(category.accentColor)

                        Text("(\(items.count) items)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Clean / None Found")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func navigateTo(category: CleanCategory) {
        switch category {
        case .systemJunk: viewModel.selectedTab = .systemJunk
        case .developerCache: viewModel.selectedTab = .developerCache
        case .appLeftovers: viewModel.selectedTab = .appLeftovers
        case .trash: viewModel.selectedTab = .trash
        }
    }
}
