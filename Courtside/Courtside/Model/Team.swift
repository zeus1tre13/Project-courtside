import Foundation
import SwiftData

@Model
final class Team {
    var id: UUID = UUID()
    var name: String = ""
    var schoolName: String?
    var isMyTeam: Bool = true
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Player.team)
    var players: [Player] = []

    @Relationship(inverse: \Game.myTeam)
    var homeGames: [Game] = []

    init(name: String, schoolName: String? = nil, isMyTeam: Bool = true) {
        self.id = UUID()
        self.name = name
        self.schoolName = schoolName
        self.isMyTeam = isMyTeam
        self.createdAt = Date()
    }

    var activePlayers: [Player] {
        players.filter { $0.isActive }.sorted { $0.jerseyNumber < $1.jerseyNumber }
    }

    var displayName: String {
        if let schoolName, !schoolName.isEmpty {
            return "\(schoolName) \(name)"
        }
        return name
    }
}
