import SwiftUI

/// A single floor-5 player row — jersey · name + stat line · chevron.
/// The lineup is the primary tappable surface in the player-first scorer,
/// so this row carries points, fouls (5 dots), and an FG line at a glance.
struct FloorPlayerRow: View {
    enum Mode {
        case normal      // nothing armed
        case selected    // this player's sheet is open
        case hint        // a stat is armed — tap to attribute
    }

    let number: String
    let name: String
    let points: Int
    let fouls: Int
    let fgLine: String
    var hot: Bool = false
    var foulOut: Bool = false
    var mode: Mode = .normal
    var action: () -> Void

    private var dotColor: Color {
        if fouls >= 4 { return CS.danger }
        if fouls >= 2 { return CS.amber }
        return CS.lineStrong
    }

    private var background: Color {
        switch mode {
        case .normal:   return CS.bgCard
        case .selected: return CS.home.opacity(0.08)
        case .hint:     return CS.made.opacity(0.05)
        }
    }

    private var borderColor: Color {
        switch mode {
        case .normal:   return CS.line
        case .selected: return CS.home
        case .hint:     return CS.made.opacity(0.4)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Jersey(number: number, color: CS.home, size: 40)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.csDisplay(17, weight: .bold))
                            .foregroundStyle(CS.ink)
                        if hot { tagBadge("HOT", CS.brand) }
                        if foulOut { tagBadge("FOUL OUT", CS.danger) }
                    }
                    HStack(spacing: 8) {
                        Text("\(points)p")
                        Text("\(fgLine) FG")
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { i in
                                Circle()
                                    .fill(i < fouls ? dotColor : CS.lineStrong.opacity(0.5))
                                    .frame(width: 5, height: 5)
                            }
                            Text("\(fouls)F").padding(.leading, 2)
                        }
                    }
                    .font(.csMono(11))
                    .foregroundStyle(CS.inkMute)
                }

                Spacer(minLength: 0)

                if mode == .hint {
                    Text("TAP")
                        .font(.csUI(10, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(CS.made)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CS.made.opacity(0.14), in: Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(mode == .selected ? CS.home : CS.inkDim)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 1.4)
            )
            .shadow(
                color: mode == .selected ? CS.home.opacity(0.25) : .clear,
                radius: 8, y: 3
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func tagBadge(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.csUI(10, weight: .heavy))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
    }
}
