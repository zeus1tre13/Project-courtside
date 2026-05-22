import SwiftUI

/// Bottom sheet that animates up when a floor player is tapped. Carries the
/// shot row (2PT / 3PT / FT, each split MADE / MISS) and an 8-cell secondary
/// stat grid. MADE is green-tinted, MISS is neutral gray — never red.
struct PlayerSheet: View {
    let number: String
    let name: String
    var onStat: (StatType) -> Void
    var onDismiss: () -> Void

    private struct ShotRow {
        let label: String
        let made: StatType
        let missed: StatType
    }

    private let shotRows: [ShotRow] = [
        ShotRow(label: "2PT", made: .fieldGoalMade, missed: .fieldGoalMissed),
        ShotRow(label: "3PT", made: .threePointMade, missed: .threePointMissed),
        ShotRow(label: "FT",  made: .freeThrowMade, missed: .freeThrowMissed),
    ]

    private let secondaryStats: [StatType] = [
        .offensiveRebound, .defensiveRebound, .assist, .steal,
        .block, .turnover, .foul,
    ]

    var body: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(CS.lineStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 2)

            header

            VStack(spacing: 8) {
                ForEach(shotRows, id: \.label) { row in
                    HStack(spacing: 6) {
                        shotButton(label: row.label, stat: row.made, made: true)
                        shotButton(label: row.label, stat: row.missed, made: false)
                    }
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 4),
                      spacing: 5) {
                ForEach(secondaryStats, id: \.self) { stat in
                    secondaryButton(stat)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(CS.bgCard)
        .clipShape(.rect(topLeadingRadius: 20, topTrailingRadius: 20))
        .overlay(alignment: .top) {
            Rectangle().fill(CS.line).frame(height: 1)
        }
        .shadow(color: CS.ink.opacity(0.18), radius: 16, y: -8)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Jersey(number: number, color: CS.home, size: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text("● RECORDING FOR")
                    .font(.csUI(11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(CS.home)
                Text("#\(number) \(name)")
                    .font(.csDisplay(18, weight: .bold))
                    .foregroundStyle(CS.ink)
            }
            Spacer()
            Button(action: onDismiss) {
                Text("Done")
                    .font(.csUI(12, weight: .semibold))
                    .foregroundStyle(CS.inkMute)
            }
        }
    }

    private func shotButton(label: String, stat: StatType, made: Bool) -> some View {
        Button {
            onStat(stat)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: made ? "checkmark" : "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(made ? CS.made : CS.inkMute)
                Text(label)
                    .font(.csUI(13, weight: .bold))
                    .foregroundStyle(made ? CS.ink : CS.inkMute)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(made ? CS.madeSoft : CS.bgStage)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(made ? CS.made.opacity(0.35) : CS.lineStrong,
                                  lineWidth: 1.2)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func secondaryButton(_ stat: StatType) -> some View {
        let isFoul = stat == .foul
        return Button {
            onStat(stat)
        } label: {
            Text(label(for: stat))
                .font(.csUI(12, weight: .bold))
                .foregroundStyle(isFoul ? CS.danger : CS.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isFoul ? CS.dangerSoft : CS.bgStage)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(isFoul ? CS.danger.opacity(0.3) : CS.line,
                                      lineWidth: 1)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func label(for stat: StatType) -> String {
        switch stat {
        case .offensiveRebound: return "OREB"
        case .defensiveRebound: return "DREB"
        case .assist:           return "AST"
        case .steal:            return "STL"
        case .block:            return "BLK"
        case .turnover:         return "TO"
        case .foul:             return "FOUL"
        default:                return stat.shortName
        }
    }
}
