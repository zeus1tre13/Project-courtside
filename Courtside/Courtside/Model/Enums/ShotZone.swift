import Foundation
import CoreGraphics

enum ShotZone: String, Codable, CaseIterable {
    // Paint
    case paintLeft
    case paintRight

    // Mid-range
    case midLeftBaseline
    case midLeftElbow
    case midFreeThrow
    case midRightElbow
    case midRightBaseline

    // Three-point
    case threeLeftCorner
    case threeLeftWing
    case threeTopOfKey
    case threeRightWing
    case threeRightCorner

    var isThreePointZone: Bool {
        switch self {
        case .threeLeftCorner, .threeLeftWing, .threeTopOfKey,
             .threeRightWing, .threeRightCorner:
            return true
        default:
            return false
        }
    }

    var isPaint: Bool {
        switch self {
        case .paintLeft, .paintRight:
            return true
        default:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .paintLeft: return "Paint (L)"
        case .paintRight: return "Paint (R)"
        case .midLeftBaseline: return "Mid Left Baseline"
        case .midLeftElbow: return "Mid Left Elbow"
        case .midFreeThrow: return "Mid Free Throw"
        case .midRightElbow: return "Mid Right Elbow"
        case .midRightBaseline: return "Mid Right Baseline"
        case .threeLeftCorner: return "3PT Left Corner"
        case .threeLeftWing: return "3PT Left Wing"
        case .threeTopOfKey: return "3PT Top of Key"
        case .threeRightWing: return "3PT Right Wing"
        case .threeRightCorner: return "3PT Right Corner"
        }
    }

    /// Normalized hit area (0...1 coordinate space) for the half-court.
    /// Origin (0,0) is top-left, (1,1) is bottom-right.
    /// Court is oriented with baseline at top, half-court line at bottom.
    var hitArea: CGRect {
        switch self {
        // Paint: center of court, near baseline
        case .paintLeft:
            return CGRect(x: 0.35, y: 0.05, width: 0.15, height: 0.25)
        case .paintRight:
            return CGRect(x: 0.50, y: 0.05, width: 0.15, height: 0.25)

        // Mid-range
        case .midLeftBaseline:
            return CGRect(x: 0.10, y: 0.02, width: 0.25, height: 0.18)
        case .midLeftElbow:
            return CGRect(x: 0.15, y: 0.20, width: 0.20, height: 0.20)
        case .midFreeThrow:
            return CGRect(x: 0.35, y: 0.30, width: 0.30, height: 0.15)
        case .midRightElbow:
            return CGRect(x: 0.65, y: 0.20, width: 0.20, height: 0.20)
        case .midRightBaseline:
            return CGRect(x: 0.65, y: 0.02, width: 0.25, height: 0.18)

        // Three-point
        case .threeLeftCorner:
            return CGRect(x: 0.00, y: 0.00, width: 0.12, height: 0.25)
        case .threeLeftWing:
            return CGRect(x: 0.02, y: 0.25, width: 0.18, height: 0.30)
        case .threeTopOfKey:
            return CGRect(x: 0.20, y: 0.45, width: 0.60, height: 0.30)
        case .threeRightWing:
            return CGRect(x: 0.80, y: 0.25, width: 0.18, height: 0.30)
        case .threeRightCorner:
            return CGRect(x: 0.88, y: 0.00, width: 0.12, height: 0.25)
        }
    }
}
