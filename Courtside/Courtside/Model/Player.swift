import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID = UUID()
    var firstName: String = ""
    var lastName: String = ""
    var jerseyNumber: String = ""
    var isActive: Bool = true

    var team: Team?

    @Relationship(inverse: \StatEvent.player)
    var statEvents: [StatEvent] = []

    init(firstName: String, lastName: String, jerseyNumber: String, isActive: Bool = true) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.jerseyNumber = jerseyNumber
        self.isActive = isActive
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var shortName: String {
        let firstInitial = firstName.prefix(1)
        return "\(firstInitial). \(lastName)"
    }

    var displayLabel: String {
        "#\(jerseyNumber) \(shortName)"
    }
}
