import Foundation

struct BoxScoreLine {
    var points: Int = 0
    var fieldGoalsMade: Int = 0
    var fieldGoalsAttempted: Int = 0
    var threePointMade: Int = 0
    var threePointAttempted: Int = 0
    var freeThrowsMade: Int = 0
    var freeThrowsAttempted: Int = 0
    var offensiveRebounds: Int = 0
    var defensiveRebounds: Int = 0
    var assists: Int = 0
    var turnovers: Int = 0
    var steals: Int = 0
    var blocks: Int = 0
    var fouls: Int = 0

    var totalRebounds: Int {
        offensiveRebounds + defensiveRebounds
    }

    var fieldGoalPercentage: Double? {
        guard fieldGoalsAttempted > 0 else { return nil }
        return Double(fieldGoalsMade) / Double(fieldGoalsAttempted)
    }

    var threePointPercentage: Double? {
        guard threePointAttempted > 0 else { return nil }
        return Double(threePointMade) / Double(threePointAttempted)
    }

    var freeThrowPercentage: Double? {
        guard freeThrowsAttempted > 0 else { return nil }
        return Double(freeThrowsMade) / Double(freeThrowsAttempted)
    }

    static func + (lhs: BoxScoreLine, rhs: BoxScoreLine) -> BoxScoreLine {
        BoxScoreLine(
            points: lhs.points + rhs.points,
            fieldGoalsMade: lhs.fieldGoalsMade + rhs.fieldGoalsMade,
            fieldGoalsAttempted: lhs.fieldGoalsAttempted + rhs.fieldGoalsAttempted,
            threePointMade: lhs.threePointMade + rhs.threePointMade,
            threePointAttempted: lhs.threePointAttempted + rhs.threePointAttempted,
            freeThrowsMade: lhs.freeThrowsMade + rhs.freeThrowsMade,
            freeThrowsAttempted: lhs.freeThrowsAttempted + rhs.freeThrowsAttempted,
            offensiveRebounds: lhs.offensiveRebounds + rhs.offensiveRebounds,
            defensiveRebounds: lhs.defensiveRebounds + rhs.defensiveRebounds,
            assists: lhs.assists + rhs.assists,
            turnovers: lhs.turnovers + rhs.turnovers,
            steals: lhs.steals + rhs.steals,
            blocks: lhs.blocks + rhs.blocks,
            fouls: lhs.fouls + rhs.fouls
        )
    }
}

enum StatCalculator {

    static func boxScoreLine(
        for player: Player,
        from allEvents: [StatEvent],
        periods: Set<Int>? = nil
    ) -> BoxScoreLine {
        let events = allEvents
            .filter { $0.playerID == player.id && !$0.isOpponentStat && !$0.isDeleted }
        return computeLine(from: events, periods: periods)
    }

    static func teamBoxScoreLine(
        from allEvents: [StatEvent],
        isOpponent: Bool = false,
        periods: Set<Int>? = nil
    ) -> BoxScoreLine {
        let events = allEvents.filter { !$0.isDeleted && $0.isOpponentStat == isOpponent }
        return computeLine(from: events, periods: periods)
    }

    private static func computeLine(
        from events: [StatEvent],
        periods: Set<Int>?
    ) -> BoxScoreLine {
        let filtered: [StatEvent]
        if let periods {
            filtered = events.filter { periods.contains($0.period) }
        } else {
            filtered = events
        }

        var line = BoxScoreLine()

        for event in filtered {
            switch event.statType {
            case .fieldGoalMade:
                line.fieldGoalsMade += 1
                line.fieldGoalsAttempted += 1
                line.points += 2
            case .fieldGoalMissed:
                line.fieldGoalsAttempted += 1
            case .threePointMade:
                line.threePointMade += 1
                line.threePointAttempted += 1
                line.fieldGoalsMade += 1
                line.fieldGoalsAttempted += 1
                line.points += 3
            case .threePointMissed:
                line.threePointAttempted += 1
                line.fieldGoalsAttempted += 1
            case .freeThrowMade:
                line.freeThrowsMade += 1
                line.freeThrowsAttempted += 1
                line.points += 1
            case .freeThrowMissed:
                line.freeThrowsAttempted += 1
            case .offensiveRebound:
                line.offensiveRebounds += 1
            case .defensiveRebound:
                line.defensiveRebounds += 1
            case .assist:
                line.assists += 1
            case .turnover:
                line.turnovers += 1
            case .steal:
                line.steals += 1
            case .block:
                line.blocks += 1
            case .foul:
                line.fouls += 1
            }
        }

        return line
    }

    static func formatPercentage(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.1f", value * 100)
    }
}
