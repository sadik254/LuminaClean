import SwiftUI
import AppKit

public struct ItemRowView: View {
    let item: JunkItem
    let onToggle: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                onToggle()
            } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(item.isSelected ? Color.blue : Color.secondary)
            }
            .buttonStyle(.plain)

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(item.category.accentColor.opacity(0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: item.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(item.category.accentColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))

                    if item.itemCount > 1 {
                        Text("\(item.itemCount) files")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                if !item.details.isEmpty {
                    Text(item.details)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(item.displayPath)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Size Badge
            Text(item.formattedSize)
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())

            // Reveal in Finder Button
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(item.isSelected ? Color.blue.opacity(0.04) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
