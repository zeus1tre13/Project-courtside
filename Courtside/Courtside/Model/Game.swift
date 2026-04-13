import Foundation
import SwiftData

@Model
final class Game {
    var id: UUID = UUID()
    var date: Date = Date()
    var formatRaw: String = GameFormat.fourQuarters.rawValue
    var opponentName: String = ""
    var trackingLevelRaw: String = OpponentTrackingLevel.team.rawValue
    var currentPeriod: Int = 1
    var isComplete: Bool = false
    var entryModeRaw: String = StatEntryMode.statFirst.rawValue
    var trackShotZones: Bool = true
    var myTeamColorHex: String = TeamColor.blue.hex
    var opponentColorHex: String = TeamColor.red.hex
    var createdAt: Date = Date()

    var myTeamID: UUID?
    var opponentTeamID: UUID?

    // No relationships — use queries with gameID instead

    var format: GameFormat {
        get { GameFormat(rawValue: formatRaw) ?? .fourQuarters }
        set { formatRaw = newValue.rawValue }
    }

    var opponentTrackingLevel: OpponentTrackingLevel {
        get { OpponentTrackingLevel(rawValue: trackingLevelRaw) ?? .team }
        set { trackingLevelRaw = newValue.rawValue }
    }

    var statEntryMode: StatEntryMode {
        get { StatEntryMode(rawValue: entryModeRaw) ?? .statFirst }
        set { entryModeRaw = newValue.rawValue }
    }

    init(
        date: Date = Date(),
        format: GameFormat = .fourQuarters,
        opponentName: String,
        opponentTrackingLevel: OpponentTrackingLevel = .team,
        statEntryMode: StatEntryMode = .statFirst
    ) {
        self.id = UUID()
        self.date = date
        self.formatRaw = format.rawValue
        self.opponentName = opponentName
        self.trackingLevelRaw = opponentTrackingLevel.rawValue
        self.entryModeRaw = statEntryMode.rawValue
        self.createdAt = Date()
    }

    var sequenceCounter: Int = 0

    var periodLabel: String {
        format.periodLabel(for: currentPeriod)
    }

    var nextSequenceNumber: Int {
        sequenceCounter += 1
        return sequenceCounter
    }

    // Scores are computed by LiveGameViewModel from queried StatEvents
    var myTeamScore: Int = 0
    var opponentScore: Int = 0

    func scoreForPeriod(_ period: Int, isOpponent: Bool) -> Int {
        guard let context = modelContext else { return 0 }
        let gameID = self.id
        let predicate = #Predicate<StatEvent> {
            $0.gameID == gameID && $0.period == period && $0.isOpponentStat == isOpponent && !$0.isDeleted
        }
        let descriptor = FetchDescriptor<StatEvent>(predicate: predicate)
        guard let events = try? context.fetch(descriptor) else { return 0 }
        return events.reduce(0) { $0 + $1.statType.pointValue }
    }
}
