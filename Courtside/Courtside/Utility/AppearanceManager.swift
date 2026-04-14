import SwiftUI
import Observation

/// App-wide theme/appearance state.
///
/// Tracks `isGymMode` — a high-contrast, light-mode-forced appearance
/// intended for bright gyms and outdoor games. Persisted via UserDefaults.
@Observable
final class ThemeManager {
    private static let gymModeKey = "gymMode"

    var isGymMode: Bool {
        didSet { UserDefaults.standard.set(isGymMode, forKey: Self.gymModeKey) }
    }

    init() {
        self.isGymMode = UserDefaults.standard.bool(forKey: Self.gymModeKey)
    }

    // MARK: - Color Scheme

    /// When gym mode is on, force light mode regardless of system setting.
    var preferredColorScheme: ColorScheme? {
        isGymMode ? .light : nil
    }

    // MARK: - Color Tokens

    /// Primary background — pure white in gym mode for maximum brightness.
    var background: Color {
        isGymMode ? .white : Color(.systemBackground)
    }

    /// Secondary/card background — very light gray in gym mode.
    var secondaryBackground: Color {
        isGymMode ? Color(white: 0.97) : Color(.systemGray6)
    }

    /// Primary text — pure black in gym mode.
    var primaryText: Color {
        isGymMode ? .black : .primary
    }

    /// Secondary text — dark gray in gym mode (not system light gray).
    var secondaryText: Color {
        isGymMode ? Color(white: 0.25) : .secondary
    }

    /// Divider/border — stronger black in gym mode.
    var border: Color {
        isGymMode ? Color(white: 0.15) : Color(.separator)
    }
}

// MARK: - Environment

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var theme: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
