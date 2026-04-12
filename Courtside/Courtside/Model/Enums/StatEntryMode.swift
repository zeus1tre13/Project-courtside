import Foundation

enum StatEntryMode: String, Codable, CaseIterable {
    case statFirst
    case playerFirst

    var displayName: String {
        switch self {
        case .statFirst: return "Stat First"
        case .playerFirst: return "Player First"
        }
    }

    var description: String {
        switch self {
        case .statFirst: return "Tap the stat, then pick the player"
        case .playerFirst: return "Tap the player, then pick the stat"
        }
    }
}
