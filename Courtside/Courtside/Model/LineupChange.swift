import Foundation
import SwiftData

@Model
final class LineupChange {
    var id: UUID = UUID()
    var period: Int = 1
    var timestamp: Date = Date()
    var sequenceNumber: Int = 0
    var playerInID: UUID = UUID()
    var playerOutID: UUID = UUID()

    var gameID: UUID?

    init(
        period: Int,
        sequenceNumber: Int,
        playerInID: UUID,
        playerOutID: UUID
    ) {
        self.id = UUID()
        self.period = period
        self.timestamp = Date()
        self.sequenceNumber = sequenceNumber
        self.playerInID = playerInID
        self.playerOutID = playerOutID
    }
}
