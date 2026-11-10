import SwiftUI

@main
struct LuminaCleanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 860, minHeight: 560)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    Task { @MainActor in
                        await UpdateService.shared.checkForUpdates()
                    }
                }
                .keyboardShortcut("U", modifiers: [.command])
            }
        }
    }
}
