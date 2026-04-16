import Foundation
import SwiftData

@Model
final class Team {
    var id: UUID = UUID()
    var name: String = ""
    var schoolName: String?
    var isMyTeam: Bool = true
    var createdAt: Date = Date()
    /// User-selected team color, stored as a hex string (e.g. "#2563EB").
    /// Nil means no explicit choice — UI falls back to a derived color.
    var colorHex: String?

    init(name: String, schoolName: String? = nil, isMyTeam: Bool = true, colorHex: String? = nil) {
        self.id = UUID()
        self.name = name
        self.schoolName = schoolName
        self.isMyTeam = isMyTeam
        self.createdAt = Date()
        self.colorHex = colorHex
    }

    var activePlayers: [Player] {
        guard let context = modelContext else { return [] }
        let teamID = self.id
        let predicate = #Predicate<Player> { $0.teamID == teamID && $0.isActive }
        let descriptor = FetchDescriptor<Player>(predicate: predicate)
        return (try? context.fetch(descriptor)) ?? []
    }

    var displayName: String {
        if let schoolName, !schoolName.isEmpty {
            return "\(schoolName) \(name)"
        }
        return name
    }
}
