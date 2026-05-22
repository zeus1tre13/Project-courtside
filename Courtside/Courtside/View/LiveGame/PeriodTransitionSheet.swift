import SwiftUI

/// End-of-period confirmation. Shows the period recap — score, margin,
/// a highlight, and any foul-trouble heads-up — before advancing.
/// "Stay" is the escape hatch for an accidental tap.
struct PeriodTransitionSheet: View {
    let viewModel: LiveGameViewModel

    private var finishedPeriod: Int { viewModel.game.currentPeriod }
    private var nextPeriod: Int { viewModel.pendingPeriod ?? finishedPeriod + 1 }
    private var finishedLabel: String { viewModel.game.format.periodLabel(for: finishedPeriod) }
    private var nextLabel: String { viewModel.game.format.periodLabel(for: nextPeriod) }

    private var myPoints: Int { viewModel.periodPoints(finishedPeriod, isOpponent: false) }
    private var oppPoints: Int { viewModel.periodPoints(finishedPeriod, isOpponent: true) }

    private var marginText: String {
        let diff = myPoints - oppPoints
        if diff > 0 { return "+\(diff) \(viewModel.myTeamName)" }
        if diff < 0 { return "+\(-diff) \(viewModel.opponentName)" }
        return "Tied"
    }
    private var marginColor: Color {
        myPoints > oppPoints ? CS.made : myPoints < oppPoints ? CS.danger : CS.inkMute
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(CS.lineStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            VStack(spacing: 4) {
                Text("END OF \(finishedLabel)")
                    .font(.csUI(11, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(CS.brand)
                Text("Move to \(nextLabel)?")
                    .font(.csDisplay(30, weight: .heavy))
                    .foregroundStyle(CS.ink)
            }
            .padding(.top, 16)

            recapCard
                .padding(.horizontal, 16)
                .padding(.top, 14)

            highlights
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Spacer(minLength: 14)

            HStack(spacing: 8) {
                Button {
                    viewModel.cancelPeriodAdvance()
                } label: {
                    Text("Stay on \(finishedLabel)")
                        .font(.csUI(14, weight: .bold))
                        .foregroundStyle(CS.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(CS.bgSoft, in: RoundedRectangle(cornerRadius: 12))
                }
                Button {
                    viewModel.confirmPeriodAdvance()
                } label: {
                    Text("Start \(nextLabel) →")
                        .font(.csUI(15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(CS.brand, in: RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .background(CS.bgStage)
    }

    // MARK: - Recap card

    private var recapCard: some View {
        VStack(spacing: 8) {
            teamRow(name: viewModel.myTeamName, points: myPoints, color: CS.home)
            Rectangle().fill(CS.line).frame(height: 1)
            teamRow(name: viewModel.opponentName, points: oppPoints, color: CS.away)
            HStack {
                Text("\(finishedLabel) RESULT")
                    .font(.csUI(10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(marginColor)
                Spacer()
                Text(marginText)
                    .font(.csDisplay(16, weight: .heavy))
                    .foregroundStyle(marginColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(marginColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
    }

    private func teamRow(name: String, points: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Jersey(number: String(name.prefix(1)).uppercased(), color: color, size: 26)
            Text(name.uppercased())
                .font(.csUI(12, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(CS.inkMute)
                .lineLimit(1)
            Spacer()
            Text("\(points)")
                .font(.csDisplay(30, weight: .heavy))
                .foregroundStyle(CS.ink)
        }
    }

    // MARK: - Highlights

    @ViewBuilder
    private var highlights: some View {
        let scorer = viewModel.topScorer(inPeriod: finishedPeriod)
        let trouble = viewModel.foulTrouble()
        if scorer != nil || !trouble.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(finishedLabel) HIGHLIGHTS")
                    .font(.csUI(11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(CS.inkDim)

                if let scorer {
                    highlightLine(
                        icon: "flame.fill", iconColor: CS.brand,
                        text: "#\(scorer.player.jerseyNumber) \(scorer.player.lastName) · \(scorer.points) pts this \(finishedLabel)",
                        warn: false
                    )
                }
                ForEach(trouble, id: \.player.id) { entry in
                    highlightLine(
                        icon: "exclamationmark.triangle.fill", iconColor: CS.amber,
                        text: "#\(entry.player.jerseyNumber) \(entry.player.lastName) · \(entry.fouls) fouls",
                        warn: true
                    )
                }
            }
        }
    }

    private func highlightLine(icon: String, iconColor: Color,
                               text: String, warn: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(iconColor)
            Text(text)
                .font(.csUI(12, weight: .semibold))
                .foregroundStyle(CS.ink)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(warn ? CS.amberSoft : CS.bgSoft)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
