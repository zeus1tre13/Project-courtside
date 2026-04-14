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

        // Try persistent storage first
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let c = try ModelContainer(for: schema, configurations: config)
            await MainActor.run { container = c }
            print("✅ ModelContainer loaded (persistent)")
            return
        } catch {
            print("⚠️ Persistent store failed: \(error)")
            // Delete stale store and retry
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let url = config.url
            let dir = url.deletingLastPathComponent()
            let name = url.lastPathComponent
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(
                    at: dir.appendingPathComponent(name + suffix)
                )
            }
            do {
                let c = try ModelContainer(for: schema, configurations: config)
                await MainActor.run { container = c }
                print("✅ ModelContainer loaded after store reset")
                return
            } catch {
                print("❌ Persistent store failed even after reset: \(error)")
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
