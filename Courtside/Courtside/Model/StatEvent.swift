import Foundation
import SwiftData

@Model
final class StatEvent {
    var id: UUID = UUID()
    var statTypeRaw: String = StatType.fieldGoalMade.rawValue
    var isOpponentStat: Bool = false
    var shotZoneRaw: String?
    var period: Int = 1
    var timestamp: Date = Date()
    var sequenceNumber: Int = 0
    var isDeleted: Bool = false

    var gameID: UUID?
    var playerID: UUID?

    var statType: StatType {
        get { StatType(rawValue: statTypeRaw) ?? .fieldGoalMade }
        set { statTypeRaw = newValue.rawValue }
    }

    var shotZone: ShotZone? {
        get {
            guard let raw = shotZoneRaw else { return nil }
            return ShotZone(rawValue: raw)
        }
        set { shotZoneRaw = newValue?.rawValue }
    }

    init(
        statType: StatType,
        isOpponentStat: Bool = false,
        shotZone: ShotZone? = nil,
        period: Int,
        sequenceNumber: Int,
        playerID: UUID? = nil
    ) {
        self.id = UUID()
        self.statTypeRaw = statType.rawValue
        self.isOpponentStat = isOpponentStat
        self.shotZoneRaw = shotZone?.rawValue
        self.period = period
        self.timestamp = Date()
        self.sequenceNumber = sequenceNumber
        self.playerID = playerID
    }
}
