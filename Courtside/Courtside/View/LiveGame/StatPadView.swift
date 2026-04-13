import SwiftUI

struct StatPadView: View {
    @Bindable var viewModel: LiveGameViewModel

    private let shotStats: [(StatType, StatType)] = [
        (.fieldGoalMade, .fieldGoalMissed),
        (.threePointMade, .threePointMissed),
        (.freeThrowMade, .freeThrowMissed),
    ]

    private let otherStats: [StatType] = [
        .offensiveRebound, .defensiveRebound,
        .assist, .turnover,
        .steal, .block,
        .foul,
    ]

    var body: some View {
        VStack(spacing: 10) {
            // Shot buttons first — right below scoreboard
            VStack(spacing: 8) {
                ForEach(shotStats, id: \.0) { made, missed in
                    HStack(spacing: 8) {
                        StatButton(stat: made, style: .made) {
                            viewModel.selectStat(made)
                        }
                        StatButton(stat: missed, style: .missed) {
                            viewModel.selectStat(missed)
                        }
                    }
                }
            }

            Divider()
                .padding(.vertical, 4)

            // Other stats below
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 8) {
                ForEach(otherStats, id: \.self) { stat in
                    StatButton(stat: stat, style: .secondary) {
                        viewModel.selectStat(stat)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

enum StatButtonStyle {
    case made, missed, secondary
}

struct StatButton: View {
    let stat: StatType
    let style: StatButtonStyle
    let action: () -> Void

    private var backgroundColor: Color {
        switch style {
        case .made: return .green.opacity(0.15)
        case .missed: return .red.opacity(0.15)
        case .secondary: return Color(.systemGray5)
        }
    }

    private var borderColor: Color {
        switch style {
        case .made: return .green.opacity(0.4)
        case .missed: return .red.opacity(0.4)
        case .secondary: return Color(.systemGray4)
        }
    }

    var body: some View {
        Button(action: action) {
            Text(stat.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
