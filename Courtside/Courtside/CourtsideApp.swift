import SwiftUI
import SwiftData

@main
struct CourtsideApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [
            Team.self,
            Player.self,
            Game.self,
            StatEvent.self,
            LineupChange.self
        ])
    }
}
