import Foundation

enum StatType: String, Codable, CaseIterable {
    case fieldGoalMade = "FGM"
    case fieldGoalMissed = "FGA_MISS"
    case threePointMade = "3PM"
    case threePointMissed = "3PA_MISS"
    case freeThrowMade = "FTM"
    case freeThrowMissed = "FTA_MISS"
    case offensiveRebound = "OREB"
    case defensiveRebound = "DREB"
    case assist = "AST"
    case turnover = "TO"
    case steal = "STL"
    case block = "BLK"
    case foul = "FOUL"

    var requiresShotZone: Bool {
        switch self {
        case .fieldGoalMade, .fieldGoalMissed,
             .threePointMade, .threePointMissed:
            return true
        default:
            return false
        }
    }

    var isMake: Bool {
        switch self {
        case .fieldGoalMade, .threePointMade, .freeThrowMade:
            return true
        default:
            return false
        }
    }

    var isMiss: Bool {
        switch self {
        case .fieldGoalMissed, .threePointMissed, .freeThrowMissed:
            return true
        default:
            return false
        }
    }

    var isShot: Bool {
        requiresShotZone || isFreeThrow
    }

    var isFreeThrow: Bool {
        self == .freeThrowMade || self == .freeThrowMissed
    }

    var pointValue: Int {
        switch self {
        case .freeThrowMade: return 1
        case .fieldGoalMade: return 2
        case .threePointMade: return 3
        default: return 0
        }
    }

    var displayName: String {
        switch self {
        case .fieldGoalMade: return "2PT Made"
        case .fieldGoalMissed: return "2PT Miss"
        case .threePointMade: return "3PT Made"
        case .threePointMissed: return "3PT Miss"
        case .freeThrowMade: return "1PT Made"
        case .freeThrowMissed: return "1PT Miss"
        case .offensiveRebound: return "OREB"
        case .defensiveRebound: return "DREB"
        case .assist: return "AST"
        case .turnover: return "TO"
        case .steal: return "STL"
        case .block: return "BLK"
        case .foul: return "FOUL"
        }
    }

    var shortName: String {
        rawValue
    }

    /// Which shot zones are valid for this stat type
    var validShotZones: [ShotZone] {
        switch self {
        case .fieldGoalMade, .fieldGoalMissed:
            // 2PT: paint + mid-range only
            return ShotZone.allCases.filter { !$0.isThreePointZone }
        case .threePointMade, .threePointMissed:
            // 3PT: three-point zones only
            return ShotZone.allCases.filter { $0.isThreePointZone }
        default:
            return []
        }
    }
}
