import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case highContrast

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .highContrast: return "High Contrast"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light, .highContrast: return .light
        }
    }
}

@Observable
final class AppearanceManager {
    var mode: AppearanceMode {
        get {
            if let raw = UserDefaults.standard.string(forKey: "appearanceMode"),
               let mode = AppearanceMode(rawValue: raw) {
                return mode
            }
            return .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "appearanceMode")
        }
    }

    var isHighContrast: Bool {
        mode == .highContrast
    }
}
