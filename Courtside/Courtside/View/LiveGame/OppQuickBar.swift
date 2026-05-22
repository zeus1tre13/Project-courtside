import SwiftUI

/// The opponent quick-score bar, pinned to the bottom of every live-game
/// state. Replaces the team toggle entirely — tapping a button records an
/// opponent stat directly, with no "active team" to get trapped in.
struct OppQuickBar: View {
    let opponentName: String
    var flashing: Bool = false
    var onScore: (StatType) -> Void
    var onMore: () -> Void

    private struct QuickButton: Identifiable {
        let id = UUID()
        let label: String
        let stat: StatType
        var danger = false
    }

    private let buttons: [QuickButton] = [
        QuickButton(label: "+2", stat: .fieldGoalMade),
        QuickButton(label: "+3", stat: .threePointMade),
        QuickButton(label: "+1", stat: .freeThrowMade),
        QuickButton(label: "REB", stat: .defensiveRebound),
        QuickButton(label: "FOUL", stat: .foul, danger: true),
    ]

    private var initial: String {
        String(opponentName.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
            .isEmpty ? "O" : String(opponentName.prefix(1)).uppercased()
    }

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Jersey(number: initial, color: CS.away, size: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(opponentName.uppercased())
                        .font(.csUI(9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(CS.brandInk)
                        .lineLimit(1)
                    Text(flashing ? "scored" : "+ quick")
                        .font(.csUI(11, weight: .bold))
                        .foregroundStyle(flashing ? CS.made : CS.inkMute)
                }
            }
            .fixedSize()

            HStack(spacing: 5) {
                ForEach(buttons) { button in
                    Button {
                        onScore(button.stat)
                    } label: {
                        Text(button.label)
                            .font(.csUI(12, weight: .bold))
                            .foregroundStyle(button.danger ? CS.danger : CS.brandInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        button.danger ? CS.danger.opacity(0.35)
                                                       : CS.away.opacity(0.35),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }

            Button(action: onMore) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CS.inkMute)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(flashing ? CS.made.opacity(0.14) : CS.awaySoft)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(flashing ? CS.made.opacity(0.5) : CS.away.opacity(0.3))
                .frame(height: 1)
        }
        .animation(.easeOut(duration: 0.2), value: flashing)
    }
}
