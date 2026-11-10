import SwiftUI

public struct SettingsView: View {
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 14) {
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("About LuminaClean")
                            .font(.system(size: 18, weight: .bold))
                        Text("Version 1.0.0 • Free & Open-Source Mac Utility")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 8)

                Divider()

                // Safety Principles
                VStack(alignment: .leading, spacing: 10) {
                    Text("Safety Principles")
                        .font(.system(size: 14, weight: .bold))

                    VStack(alignment: .leading, spacing: 12) {
                        principleRow(
                            icon: "lock.shield.fill",
                            color: .green,
                            title: "Zero System Risk",
                            description: "LuminaClean never touches macOS system binaries, SIP-protected paths, or system preferences."
                        )

                        principleRow(
                            icon: "folder.badge.person.crop",
                            color: .blue,
                            title: "Personal Files Untouched",
                            description: "Your Documents, Desktop, Downloads, Photos, and iCloud drive are strictly excluded from automated cleaning."
                        )

                        principleRow(
                            icon: "eye.fill",
                            color: .purple,
                            title: "Full Transparency",
                            description: "Every detected item shows its exact path, file count, and can be inspected directly in Finder before deletion."
                        )

                        principleRow(
                            icon: "network.slash",
                            color: .orange,
                            title: "100% Offline & Private",
                            description: "No analytics, no telemetry, no tracking, and no external network connections."
                        )
                    }
                }

                Divider()

                // Developer Note
                VStack(alignment: .leading, spacing: 6) {
                    Text("Why LuminaClean?")
                        .font(.system(size: 14, weight: .bold))
                    Text("Commercial cleaner apps charge $30–$40 annual subscriptions for basic filesystem clearing. LuminaClean was built to give Mac users and developers a free, lightweight, privacy-respecting native alternative without bloatware or background daemons.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }

                Spacer()
            }
            .padding(24)
        }
    }

    private func principleRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
