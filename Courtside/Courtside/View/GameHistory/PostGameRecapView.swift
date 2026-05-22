import SwiftUI

/// The Recap tab — period strip, team comparison bars, top performers, and a
/// shot-chart preview that opens the full chart.
struct PostGameRecapView: View {
    let game: Game
    let events: [StatEvent]
    let myPlayers: [Player]
    let myTeamName: String
    var onOpenShotChart: () -> Void

    private var myLine: BoxScoreLine {
        StatCalculator.teamBoxScoreLine(from: events, isOpponent: false)
    }
    private var oppLine: BoxScoreLine {
        StatCalculator.teamBoxScoreLine(from: events, isOpponent: true)
    }

    private var periodCount: Int {
        max(game.format.periodCount, game.currentPeriod)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            periodStrip
            comparison
            topPerformers
            if game.trackShotZones {
                shotPreview
            }
        }
        .padding(.vertical, 14)
    }

    // MARK: - Period strip

    private var periodStrip: some View {
        VStack(spacing: 8) {
            HStack {
                Text("TEAM")
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(1...periodCount, id: \.self) { period in
                    Text(game.format.periodLabel(for: period))
                        .frame(maxWidth: .infinity)
                }
                Text("TOT").frame(width: 42, alignment: .trailing)
            }
            .font(.csUI(9, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(CS.inkDim)

            periodRow(name: myTeamName, color: CS.home, isOpponent: false, total: myLine.points)
            periodRow(name: game.opponentName, color: CS.away, isOpponent: true, total: oppLine.points)
        }
        .padding(12)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
        .padding(.horizontal, 14)
    }

    private func periodRow(name: String, color: Color, isOpponent: Bool, total: Int) -> some View {
        HStack {
            Text(name.isEmpty ? (isOpponent ? "Opponent" : "Team") : name)
                .font(.csUI(12, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(1...periodCount, id: \.self) { period in
                Text("\(game.scoreForPeriod(period, isOpponent: isOpponent))")
                    .font(.csMono(13, weight: .semibold))
                    .foregroundStyle(CS.ink)
                    .frame(maxWidth: .infinity)
            }
            Text("\(total)")
                .font(.csDisplay(20, weight: .heavy))
                .foregroundStyle(color)
                .frame(width: 42, alignment: .trailing)
        }
    }

    // MARK: - Comparison

    private var comparison: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TEAM COMPARISON")
            VStack(spacing: 0) {
                compareRow("FG", home: .shot(myLine.fieldGoalsMade, myLine.fieldGoalsAttempted),
                           away: .shot(oppLine.fieldGoalsMade, oppLine.fieldGoalsAttempted))
                compareRow("3PT", home: .shot(myLine.threePointMade, myLine.threePointAttempted),
                           away: .shot(oppLine.threePointMade, oppLine.threePointAttempted))
                compareRow("FT", home: .shot(myLine.freeThrowsMade, myLine.freeThrowsAttempted),
                           away: .shot(oppLine.freeThrowsMade, oppLine.freeThrowsAttempted))
                compareRow("Rebounds", home: .raw(myLine.totalRebounds),
                           away: .raw(oppLine.totalRebounds))
                compareRow("Assists", home: .raw(myLine.assists),
                           away: .raw(oppLine.assists))
                compareRow("Turnovers", home: .raw(myLine.turnovers),
                           away: .raw(oppLine.turnovers), inverse: true, last: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background(CS.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
        }
        .padding(.horizontal, 14)
    }

    private enum CompareValue {
        case raw(Int)
        case shot(Int, Int)

        var primary: Int {
            switch self {
            case .raw(let v): return v
            case .shot(let m, _): return m
            }
        }
        var text: String {
            switch self {
            case .raw(let v): return "\(v)"
            case .shot(let m, let a): return "\(m)/\(a)"
            }
        }
        var percent: String? {
            switch self {
            case .raw: return nil
            case .shot(let m, let a):
                guard a > 0 else { return nil }
                return "\(Int(Double(m) / Double(a) * 100))%"
            }
        }
    }

    private func compareRow(_ label: String, home: CompareValue, away: CompareValue,
                            inverse: Bool = false, last: Bool = false) -> some View {
        let homeVal = home.primary
        let awayVal = away.primary
        let total = homeVal + awayVal
        let homeFrac = total > 0 ? CGFloat(homeVal) / CGFloat(total) : 0.5
        let homeWins = inverse ? homeVal < awayVal : homeVal > awayVal
        return VStack(spacing: 6) {
            HStack {
                valueText(home, percent: home.percent,
                          color: homeWins ? CS.home : CS.inkMute, align: .leading)
                Text(label.uppercased())
                    .font(.csUI(11, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(CS.inkMute)
                    .frame(maxWidth: .infinity)
                valueText(away, percent: away.percent,
                          color: !homeWins ? CS.away : CS.inkMute, align: .trailing)
            }
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle().fill(CS.home).frame(width: geo.size.width * homeFrac)
                    Rectangle().fill(CS.away.opacity(0.7))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            if !last { Rectangle().fill(CS.line).frame(height: 1) }
        }
    }

    private func valueText(_ value: CompareValue, percent: String?,
                           color: Color, align: HorizontalAlignment) -> some View {
        HStack(spacing: 4) {
            Text(value.text)
                .font(.csMono(13, weight: .bold))
                .foregroundStyle(color)
            if let percent {
                Text(percent)
                    .font(.csMono(11))
                    .foregroundStyle(CS.inkDim)
            }
        }
        .frame(width: 96, alignment: align == .leading ? .leading : .trailing)
    }

    // MARK: - Top performers

    private var topPerformers: some View {
        let lines = myPlayers.map { ($0, StatCalculator.boxScoreLine(for: $0, from: events)) }
        let leader = lines.max { $0.1.points < $1.1.points }
        let boards = lines.max { $0.1.totalRebounds < $1.1.totalRebounds }
        let dimes = lines.max { $0.1.assists < $1.1.assists }
        return VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TOP PERFORMERS")
            VStack(spacing: 8) {
                if let leader, leader.1.points > 0 {
                    performerCard(leader.0, kicker: "GAME HIGH · POINTS",
                                  value: "\(leader.1.points)",
                                  sub: "\(leader.1.fieldGoalsMade)/\(leader.1.fieldGoalsAttempted) FG · \(leader.1.threePointMade)/\(leader.1.threePointAttempted) 3PT",
                                  accent: true)
                }
                if let boards, boards.1.totalRebounds > 0 {
                    performerCard(boards.0, kicker: "BOARDS",
                                  value: "\(boards.1.totalRebounds)",
                                  sub: "\(boards.1.points)p · \(boards.1.blocks) BLK",
                                  accent: false)
                }
                if let dimes, dimes.1.assists > 0 {
                    performerCard(dimes.0, kicker: "DIMES",
                                  value: "\(dimes.1.assists)",
                                  sub: "\(dimes.1.points)p · \(dimes.1.steals) STL",
                                  accent: false)
                }
            }
            .padding(.horizontal, 14)
        }
    }

    private func performerCard(_ player: Player, kicker: String, value: String,
                               sub: String, accent: Bool) -> some View {
        HStack(spacing: 12) {
            Jersey(number: player.jerseyNumber, color: CS.home, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(player.lastName.isEmpty ? player.fullName : player.lastName)
                    .font(.csDisplay(18, weight: .bold))
                    .foregroundStyle(CS.ink)
                Text(kicker)
                    .font(.csUI(10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(accent ? CS.brand : CS.inkMute)
                Text(sub)
                    .font(.csMono(11))
                    .foregroundStyle(CS.inkMute)
            }
            Spacer(minLength: 0)
            Text(value)
                .font(.csDisplay(38, weight: .heavy))
                .foregroundStyle(accent ? CS.brand : CS.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(accent ? CS.brand.opacity(0.06) : CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(accent ? CS.brand.opacity(0.3) : CS.line, lineWidth: 1)
        )
    }

    // MARK: - Shot preview

    private var shotPreview: some View {
        let data = ShotChartCalculator.compute(from: events, isOpponent: false)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionLabel("SHOT CHART PREVIEW")
                Spacer()
                Text("Open →")
                    .font(.csUI(11, weight: .bold))
                    .foregroundStyle(CS.brand)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            if data.isEmpty {
                Text("No shots with a recorded zone.")
                    .font(.csUI(12))
                    .foregroundStyle(CS.inkMute)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            } else {
                ShotHeatCourt(data: data, compact: true)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
        }
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenShotChart)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.csUI(11, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(CS.inkDim)
    }
}
