import SwiftUI

/// Play-by-play — the recorded events surfaced as a chronological feed,
/// grouped quarter by quarter.
struct PlayByPlayView: View {
    let game: Game
    let events: [StatEvent]
    let players: [Player]
    let myTeamName: String

    private var orderedEvents: [StatEvent] {
        events.sorted { $0.sequenceNumber < $1.sequenceNumber }
    }

    private var periods: [Int] {
        Array(Set(events.map(\.period))).sorted()
    }

    var body: some View {
        if events.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(periods, id: \.self) { period in
                        periodSection(period)
                    }
                }
                .padding(.vertical, 14)
            }
            .scrollIndicators(.hidden)
            .background(CS.bgStage)
        }
    }

    // MARK: - Period section

    private func periodSection(_ period: Int) -> some View {
        let periodEvents = orderedEvents.filter { $0.period == period }
        let myPts = game.scoreForPeriod(period, isOpponent: false)
        let oppPts = game.scoreForPeriod(period, isOpponent: true)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(game.format.periodLabel(for: period))
                    .font(.csDisplay(20, weight: .heavy))
                    .foregroundStyle(CS.ink)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(myPts)").foregroundStyle(myPts >= oppPts ? CS.home : CS.inkMute)
                    Text("–").foregroundStyle(CS.inkDim)
                    Text("\(oppPts)").foregroundStyle(oppPts > myPts ? CS.away : CS.inkMute)
                }
                .font(.csMono(13, weight: .bold))
                Text("\(periodEvents.count) play\(periodEvents.count == 1 ? "" : "s")")
                    .font(.csUI(10, weight: .semibold))
                    .foregroundStyle(CS.inkDim)
            }
            .padding(.horizontal, 14)

            VStack(spacing: 4) {
                ForEach(periodEvents, id: \.id) { event in
                    row(event)
                }
            }
            .padding(.horizontal, 14)
        }
    }

    private func row(_ event: StatEvent) -> some View {
        let side = event.isOpponentStat ? CS.away : CS.home
        let points = event.statType.pointValue
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(side)
                .frame(width: 3, height: 18)
            Text(name(for: event))
                .font(.csUI(13, weight: .bold))
                .foregroundStyle(side)
            Text("· \(label(for: event))")
                .font(.csUI(13))
                .foregroundStyle(CS.inkMute)
                .lineLimit(1)
            Spacer(minLength: 0)
            if points > 0 {
                Text("+\(points)")
                    .font(.csDisplay(16, weight: .heavy))
                    .foregroundStyle(side)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(CS.line, lineWidth: 1))
    }

    // MARK: - Helpers

    private func name(for event: StatEvent) -> String {
        if let pid = event.playerID, let player = players.first(where: { $0.id == pid }) {
            return "#\(player.jerseyNumber) \(player.lastName)"
        }
        if event.isOpponentStat {
            return game.opponentName.isEmpty ? "Opponent" : game.opponentName
        }
        return myTeamName
    }

    private func label(for event: StatEvent) -> String {
        var base = event.statType.displayName
        if let zone = event.shotZone {
            base += " · \(zone.shortLabel)"
        }
        return base
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 34))
                .foregroundStyle(CS.inkDim)
            Text("No plays recorded")
                .font(.csDisplay(20, weight: .bold))
                .foregroundStyle(CS.ink)
            Text("This game has no logged events.")
                .font(.csUI(13))
                .foregroundStyle(CS.inkMute)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CS.bgStage)
    }
}
