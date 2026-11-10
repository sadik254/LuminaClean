import SwiftUI

public struct CategoryDetailView: View {
    let category: CleanCategory
    @Bindable var viewModel: AppViewModel

    private var categoryItems: [JunkItem] {
        viewModel.items(for: category)
    }

    private var selectedSize: Int64 {
        viewModel.categorySelectedSize(for: category)
    }

    private var totalSize: Int64 {
        viewModel.categorySize(for: category)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            Divider()

            // List of Items
            if categoryItems.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(categoryItems) { item in
                        ItemRowView(item: item) {
                            viewModel.toggleItemSelection(id: item.id)
                        }
                        .listRowSeparator(.visible)
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            // Bottom Action Bar
            bottomBar
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: category.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(category.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(category.title)
                    .font(.system(size: 18, weight: .bold))

                Text(category.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if totalSize > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(category.accentColor)

                    Text("\(categoryItems.count) items found")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.secondary.opacity(0.04))
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack {
            if !categoryItems.isEmpty {
                Button("Select All") {
                    viewModel.setAllSelected(in: category, selected: true)
                }
                .buttonStyle(.link)
                .font(.system(size: 12))

                Text("•")
                    .foregroundStyle(.tertiary)

                Button("Deselect All") {
                    viewModel.setAllSelected(in: category, selected: false)
                }
                .buttonStyle(.link)
                .font(.system(size: 12))
            }

            Spacer()

            if selectedSize > 0 {
                Text("Selected: \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.showCleanConfirmation = true
                } label: {
                    Label("Clean Selected", systemImage: "sparkles")
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(category.accentColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green.opacity(0.8))

            Text("No Junk Detected")
                .font(.system(size: 16, weight: .semibold))

            Text(viewModel.items.isEmpty ? "Click 'Start Deep Scan' on the Overview tab to scan this category." : "This category is completely clean. No action needed!")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            if viewModel.items.isEmpty {
                Button("Start Scan Now") {
                    viewModel.startScan()
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
    }
}
