import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static var previewContainer: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Team.self, Player.self, Game.self,
                 StatEvent.self, LineupChange.self,
            configurations: config
        )

        // Sample team
        let team = Team(name: "Eagles", schoolName: "Lincoln High")
        container.mainContext.insert(team)

        let players = [
            Player(firstName: "Marcus", lastName: "Johnson", jerseyNumber: "3"),
            Player(firstName: "Tyler", lastName: "Williams", jerseyNumber: "11"),
            Player(firstName: "Devon", lastName: "Brown", jerseyNumber: "15"),
            Player(firstName: "Chris", lastName: "Davis", jerseyNumber: "22"),
            Player(firstName: "Jordan", lastName: "Miller", jerseyNumber: "24"),
            Player(firstName: "Andre", lastName: "Wilson", jerseyNumber: "30"),
            Player(firstName: "DeShawn", lastName: "Moore", jerseyNumber: "32"),
            Player(firstName: "Jamal", lastName: "Taylor", jerseyNumber: "33"),
            Player(firstName: "Kenji", lastName: "Anderson", jerseyNumber: "40"),
            Player(firstName: "Malik", lastName: "Thomas", jerseyNumber: "44"),
        ]

        for player in players {
            player.teamID = team.id
            container.mainContext.insert(player)
        }

        return container
    }
}
