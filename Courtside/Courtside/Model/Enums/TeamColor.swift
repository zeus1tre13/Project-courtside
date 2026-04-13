import SwiftUI

enum TeamColor: String, CaseIterable, Identifiable {
    case blue, red, green, gold, purple, orange, black, gray, maroon, navy, teal, pink

    var id: String { rawValue }

    var hex: String {
        switch self {
        case .blue:   return "#2563EB"
        case .red:    return "#DC2626"
        case .green:  return "#16A34A"
        case .gold:   return "#CA8A04"
        case .purple: return "#9333EA"
        case .orange: return "#EA580C"
        case .black:  return "#1C1917"
        case .gray:   return "#6B7280"
        case .maroon: return "#881337"
        case .navy:   return "#1E3A5F"
        case .teal:   return "#0D9488"
        case .pink:   return "#DB2777"
        }
    }

    var color: Color {
        Color(hex: hex)
    }

    var displayName: String {
        rawValue.capitalized
    }

    static func from(hex: String) -> TeamColor {
        allCases.first { $0.hex == hex } ?? .blue
    }
}

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
