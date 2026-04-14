import SwiftUI
import SwiftData

@main
struct CourtsideApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var container: ModelContainer?
    @State private var loadError: String?
    @State private var theme = ThemeManager()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
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
                        Color(.systemBackground)
                    }
                }
                .environment(\.theme, theme)
                .preferredColorScheme(theme.preferredColorScheme)
                .task {
                    await loadContainer()
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                        .task {
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            withAnimation(.easeOut(duration: 0.35)) {
                                showSplash = false
                            }
                        }
                }
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

// MARK: - Splash

private struct SplashView: View {
    var body: some View {
        GeometryReader { geo in
            Image("CourtsideSplash")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .ignoresSafeArea()
        }
    }
}
