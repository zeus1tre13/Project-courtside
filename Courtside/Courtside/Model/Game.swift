import Foundation
import SwiftData

@Model
final class Game {
    var id: UUID = UUID()
    var date: Date = Date()
    var format: GameFormat = GameFormat.fourQuarters
    var opponentName: String = ""
    var opponentTrackingLevel: OpponentTrackingLevel = OpponentTrackingLevel.team
    var currentPeriod: Int = 1
    var isComplete: Bool = false
    var statEntryMode: StatEntryMode = StatEntryMode.statFirst
    var createdAt: Date = Date()

    var myTeam: Team?
    var opponentTeam: Team?

    @Relationship(deleteRule: .cascade, inverse: \StatEvent.game)
    var statEvents: [StatEvent] = []

    @Relationship(deleteRule: .cascade, inverse: \LineupChange.game)
    var lineupChanges: [LineupChange] = []

    init(
        date: Date = Date(),
        format: GameFormat = .fourQuarters,
        opponentName: String,
        opponentTrackingLevel: OpponentTrackingLevel = .team,
        statEntryMode: StatEntryMode = .statFirst
    ) {
        self.id = UUID()
        self.date = date
        self.format = format
        self.opponentName = opponentName
        self.opponentTrackingLevel = opponentTrackingLevel
        self.statEntryMode = statEntryMode
        self.createdAt = Date()
    }

    var activeStatEvents: [StatEvent] {
        statEvents.filter { !$0.isDeleted }
    }

    var myTeamEvents: [StatEvent] {
        activeStatEvents.filter { !$0.isOpponentStat }
    }

    var opponentEvents: [StatEvent] {
        activeStatEvents.filter { $0.isOpponentStat }
    }

    var myTeamScore: Int {
        myTeamEvents.reduce(0) { $0 + $1.statType.pointValue }
    }

    var opponentScore: Int {
        opponentEvents.reduce(0) { $0 + $1.statType.pointValue }
    }

    var periodLabel: String {
        format.periodLabel(for: currentPeriod)
    }

    var nextSequenceNumber: Int {
        let maxSeq = statEvents.map(\.sequenceNumber).max() ?? 0
        return maxSeq + 1
    }

    func scoreForPeriod(_ period: Int, isOpponent: Bool) -> Int {
        let events = isOpponent ? opponentEvents : myTeamEvents
        return events
            .filter { $0.period == period }
            .reduce(0) { $0 + $1.statType.pointValue }
    }
}
