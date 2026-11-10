import SwiftUI

public struct SettingsView: View {
    @Bindable var viewModel: AppViewModel

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // App Branding Header
                headerSection

                Divider()

                // Software Updates Card
                softwareUpdateSection

                Divider()

                // Safety Principles
                safetyPrinciplesSection

                Divider()

                // Developer Note
                aboutSection

                Spacer()
            }
            .padding(24)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("LuminaClean")
                    .font(.system(size: 20, weight: .bold))
                Text("Version \(viewModel.updateService.currentVersion) • Free & Open-Source Mac Utility")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Software Updates Section
    private var softwareUpdateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Software Updates", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                if case .checking = viewModel.updateService.status {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondary.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 12) {
                    switch viewModel.updateService.status {
                    case .idle:
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Check for Latest Releases")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Verify with GitHub if a newer version of LuminaClean is available.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                Task {
                                    await viewModel.updateService.checkForUpdates()
                                }
                            } label: {
                                Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.bordered)
                        }

                    case .checking:
                        HStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.small)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Checking for updates...")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Querying the official LuminaClean GitHub repository.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)

                    case .upToDate(let current):
                        HStack(alignment: .center) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("LuminaClean is up to date")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Version \(current) is currently the latest available release.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Check Again") {
                                Task {
                                    await viewModel.updateService.checkForUpdates()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                    case .available(let version, let release):
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("New Version Available: v\(version)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.blue)
                                    Text(release.name)
                                        .font(.system(size: 12, weight: .medium))
                                    if let body = release.body, !body.isEmpty {
                                        Text(body)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(3)
                                            .padding(.top, 2)
                                    }
                                }
                                Spacer()
                            }

                            HStack(spacing: 10) {
                                Button {
                                    Task {
                                        await viewModel.updateService.downloadAndInstall(release: release)
                                    }
                                } label: {
                                    Label("Update & Restart Now", systemImage: "arrow.down.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)

                                if let url = URL(string: release.htmlUrl) {
                                    Link("Release Notes", destination: url)
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 8)
                                }
                            }
                        }

                    case .downloading(let progress):
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Downloading Update...")
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: progress)
                                .tint(.blue)
                            Text("Downloading release archive from GitHub. The app will install and restart automatically.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                    case .installing:
                        HStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.small)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Installing Update & Restarting...")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Extracting files and relaunching LuminaClean. Please wait a moment.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)

                    case .error(let message):
                        HStack(alignment: .center) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Update Check Failed")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(message)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Retry") {
                                Task {
                                    await viewModel.updateService.checkForUpdates()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Safety Principles
    private var safetyPrinciplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safety Principles")
                .font(.system(size: 15, weight: .bold))

            VStack(alignment: .leading, spacing: 14) {
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
                    description: "Your Documents, Desktop, Downloads, Photos, and code repositories are strictly excluded from automated cleaning."
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
                    description: "No analytics, no telemetry, no tracking, and no external connections except user-initiated release checks."
                )
            }
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why LuminaClean?")
                .font(.system(size: 15, weight: .bold))
            Text("Commercial cleaner apps charge $30–$40 annual subscriptions for basic filesystem clearing. LuminaClean was built to give Mac users and developers a free, lightweight, privacy-respecting native alternative without bloatware or background daemons.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            HStack(spacing: 16) {
                Link(destination: URL(string: "https://github.com/sadik254/LuminaClean")!) {
                    Label("GitHub Repository", systemImage: "link")
                        .font(.system(size: 12))
                }
                Link(destination: URL(string: "https://github.com/sadik254/LuminaClean/releases")!) {
                    Label("All Releases", systemImage: "tag")
                        .font(.system(size: 12))
                }
            }
            .padding(.top, 6)
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
