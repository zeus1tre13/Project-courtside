import Foundation

enum GameFormat: String, Codable, CaseIterable {
    case fourQuarters
    case twoHalves

    var periodCount: Int {
        switch self {
        case .fourQuarters: return 4
        case .twoHalves: return 2
        }
    }

    var displayName: String {
        switch self {
        case .fourQuarters: return "4 Quarters"
        case .twoHalves: return "2 Halves"
        }
    }

    func periodLabel(for period: Int) -> String {
        switch self {
        case .fourQuarters:
            return period <= 4 ? "Q\(period)" : "OT\(period - 4)"
        case .twoHalves:
            return period <= 2 ? "H\(period)" : "OT\(period - 2)"
        }
    }

    func isOvertime(_ period: Int) -> Bool {
        return period > periodCount
    }
}
