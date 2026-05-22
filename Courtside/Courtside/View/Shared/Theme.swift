import SwiftUI

/// Courtside design tokens — the warm-paper, light-mode system from the
/// "Direction B · Player-First" redesign handoff. Use these directly rather
/// than system colors so the live-game surfaces stay on-brand and consistent.
enum CS {
    // MARK: - Surfaces
    static let bgApp      = Color(hex: "#F4F2EC")  // warm-paper backdrop
    static let bgStage    = Color(hex: "#FBFAF6")  // screen background
    static let bgCard     = Color(hex: "#FFFFFF")  // elevated card
    static let bgSoft     = Color(hex: "#ECEAE3")  // subtle chip / pill
    static let bgSofter   = Color(hex: "#F1EFE8")
    static let line       = Color(hex: "#E2DED5")
    static let lineStrong = Color(hex: "#C8C3B6")

    // MARK: - Ink
    static let ink     = Color(hex: "#14141A")
    static let ink2    = Color(hex: "#2A2A33")
    static let inkMute = Color(hex: "#6B6B73")
    static let inkDim  = Color(hex: "#9A9AA3")

    // MARK: - Identity
    static let brand     = Color(hex: "#E8492A")  // basketball-leather red-orange
    static let brandSoft = Color(hex: "#FBE7DF")
    static let brandInk  = Color(hex: "#B8341A")
    static let home      = Color(hex: "#1D6CFF")  // your team — cool blue
    static let homeSoft  = Color(hex: "#E3ECFF")
    static let away      = Color(hex: "#E8492A")  // opponent — warm
    static let awaySoft  = Color(hex: "#FBE7DF")

    // MARK: - Semantic
    // Red is reserved for destructive only (End / Foul / Tech).
    // A miss is NEUTRAL gray, never red.
    static let made      = Color(hex: "#1AA46E")  // confirmed positive event
    static let madeSoft  = Color(hex: "#DFF3EA")
    static let missInk   = Color(hex: "#6B6B73")
    static let missSoft  = Color(hex: "#ECEAE3")
    static let danger    = Color(hex: "#DC2626")  // foul / end / destructive only
    static let dangerSoft = Color(hex: "#FCE5E5")
    static let amber     = Color(hex: "#E89B2A")  // warning / approaching limit
    static let amberSoft = Color(hex: "#FBEDD2")
}

extension Font {
    /// Display face — scores, titles, section headers, large numerics.
    /// Big Shoulders Display isn't bundled; a heavy condensed system face is
    /// the documented fallback.
    static func csDisplay(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }

    /// UI body / buttons / labels.
    static func csUI(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// Timecodes and statistical numerics.
    static func csMono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
