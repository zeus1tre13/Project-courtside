import Foundation

// MARK: - Zone-level stats

struct ShotZoneStat {
    let zone: ShotZone
    let made: Int
    let attempted: Int

    var percentage: Double? {
        guard attempted > 0 else { return nil }
        return Double(made) / Double(attempted)
    }

    /// Zones with fewer than 3 attempts show a raw count, not a percentage.
    var hasEnoughAttempts: Bool { attempted >= 3 }
}

// MARK: - Aggregate chart data

struct ShotChartData {
    /// Zone stats — only zones with at least one attempt are present.
    let zoneStats: [ShotZone: ShotZoneStat]
    let ftMade: Int
    let ftAttempted: Int
    /// All non-deleted field goal events that have a zone attached.
    let fieldGoalEvents: [StatEvent]

    var ftPercentage: Double? {
        guard ftAttempted > 0 else { return nil }
        return Double(ftMade) / Double(ftAttempted)
    }

    var totalFieldGoalAttempts: Int {
        zoneStats.values.reduce(0) { $0 + $1.attempted }
    }

    var isEmpty: Bool {
        totalFieldGoalAttempts == 0 && ftAttempted == 0
    }

    /// Max attempts in any single zone — used to scale volume coloring.
    var maxZoneAttempts: Int {
        zoneStats.values.map(\.attempted).max() ?? 1
    }

    func events(for zone: ShotZone) -> [StatEvent] {
        fieldGoalEvents.filter { $0.shotZone == zone }
    }

    static let empty = ShotChartData(
        zoneStats: [:],
        ftMade: 0,
        ftAttempted: 0,
        fieldGoalEvents: []
    )
}

// MARK: - Calculator

enum ShotChartCalculator {

    /// Build ShotChartData from a flat array of StatEvents.
    ///
    /// - Parameters:
    ///   - events:     The full event array for the scope (game, season, etc.).
    ///   - isOpponent: Whether to aggregate opponent events or team events.
    ///   - playerID:   If provided, restricts to a single player.
    static func compute(
        from events: [StatEvent],
        isOpponent: Bool = false,
        playerID: UUID? = nil
    ) -> ShotChartData {
        let filtered = events.filter {
            !$0.isDeleted &&
            $0.isOpponentStat == isOpponent &&
            (playerID == nil || $0.playerID == playerID)
        }

        let ftMade   = filtered.filter { $0.statType == .freeThrowMade }.count
        let ftMissed = filtered.filter { $0.statType == .freeThrowMissed }.count

        // Only field goal events where a zone was recorded
        let fgEvents = filtered.filter { $0.statType.requiresShotZone && $0.shotZone != nil }

        var zoneStats: [ShotZone: ShotZoneStat] = [:]
        for zone in ShotZone.allCases {
            let zoneEvents = fgEvents.filter { $0.shotZone == zone }
            guard !zoneEvents.isEmpty else { continue }
            let made = zoneEvents.filter { $0.statType.isMake }.count
            zoneStats[zone] = ShotZoneStat(zone: zone, made: made, attempted: zoneEvents.count)
        }

        return ShotChartData(
            zoneStats: zoneStats,
            ftMade: ftMade,
            ftAttempted: ftMade + ftMissed,
            fieldGoalEvents: fgEvents
        )
    }
}
