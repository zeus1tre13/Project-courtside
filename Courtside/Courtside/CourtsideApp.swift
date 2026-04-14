import SwiftUI
import SwiftData

@main
struct CourtsideApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var container: ModelContainer?
    @State private var loadError: String?
    @State private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    HomeView()
                        .modelContainer(container)
                } else if let loadError {
                    ContentUnavailableView(
                        "Database Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else {
                    ProgressView("Loading…")
                }
            }
            .environment(\.theme, theme)
            .preferredColorScheme(theme.preferredColorScheme)
            .task {
                await loadContainer()
            }
        }
    }

    private func loadContainer() async {
        let schema = Schema([
            Team.self,
            Player.self,
            Game.self,
            StatEvent.self,
            LineupChange.self,
        ])

        let cloudKitContainerID = "iCloud.com.xciv.courtside"

        // Try CloudKit-synced persistent storage first
        do {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(cloudKitContainerID)
            )
            let c = try ModelContainer(for: schema, configurations: config)
            await MainActor.run { container = c }
            print("✅ ModelContainer loaded (CloudKit private)")
            return
        } catch {
            print("⚠️ CloudKit store failed: \(error)")
            // Delete stale store and retry without CloudKit — local-only so the app still works
            let localConfig = ModelConfiguration(isStoredInMemoryOnly: false)
            let url = localConfig.url
            let dir = url.deletingLastPathComponent()
            let name = url.lastPathComponent
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(
                    at: dir.appendingPathComponent(name + suffix)
                )
            }
            do {
                let c = try ModelContainer(for: schema, configurations: localConfig)
                await MainActor.run { container = c }
                print("✅ ModelContainer loaded local-only after store reset")
                return
            } catch {
                print("❌ Local store failed even after reset: \(error)")
            }
        }

        // Fallback: in-memory
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let c = try ModelContainer(for: schema, configurations: config)
            await MainActor.run { container = c }
            print("⚠️ ModelContainer loaded (in-memory fallback)")
        } catch {
            await MainActor.run { loadError = "\(error)" }
            print("❌ All ModelContainer attempts failed: \(error)")
        }
    }
}
