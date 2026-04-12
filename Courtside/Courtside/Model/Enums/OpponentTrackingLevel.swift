import Foundation

enum OpponentTrackingLevel: String, Codable, CaseIterable {
    case individual
    case team
    case none

    var displayName: String {
        switch self {
        case .individual: return "Track Individual Players"
        case .team: return "Track Team Totals"
        case .none: return "Don't Track"
        }
    }

    var description: String {
        switch self {
        case .individual: return "Log stats for each opponent player"
        case .team: return "Log opponent stats as team totals only"
        case .none: return "Only track your team's stats"
        }
    }
}
