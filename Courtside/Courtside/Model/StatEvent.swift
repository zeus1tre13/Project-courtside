import Foundation
import SwiftData

@Model
final class StatEvent {
    var id: UUID = UUID()
    var statType: StatType = StatType.fieldGoalMade
    var isOpponentStat: Bool = false
    var shotZone: ShotZone?
    var period: Int = 1
    var timestamp: Date = Date()
    var sequenceNumber: Int = 0
    var isDeleted: Bool = false

    var game: Game?
    var player: Player?

    init(
        statType: StatType,
        isOpponentStat: Bool = false,
        shotZone: ShotZone? = nil,
        period: Int,
        sequenceNumber: Int,
        player: Player? = nil
    ) {
        self.id = UUID()
        self.statType = statType
        self.isOpponentStat = isOpponentStat
        self.shotZone = shotZone
        self.period = period
        self.timestamp = Date()
        self.sequenceNumber = sequenceNumber
        self.player = player
    }
}
