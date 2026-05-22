import SwiftUI
import SwiftData

/// Box score rebuilt for iPhone — grouped stat columns instead of an
/// 11-column horizontal scroll. No +/- column (Courtside doesn't track
/// minutes). Starters get a card background; bench is bare.
struct BoxScoreView: View {
    let game: Game
    @Query private var allEvents: [StatEvent]
    @Query private var allPlayers: [Player]

    @State private var teamSide: TeamSide = .mine
    @State private var lineupFilter: LineupFilter = .all
    @State private var periodFilter: Set<Int> = []
    @State private var editTarget: EditTarget?

    enum TeamSide { case mine, opponent }
    enum LineupFilter { case all, starters, bench }

    private struct EditTarget: Identifiable {
        let id = UUID()
        let player: Player?
        let isOpponent: Bool
    }

    // MARK: - Data

    private var gameEvents: [StatEvent] {
        allEvents.filter { $0.gameID == game.id && !$0.isDeleted }
    }

    private var scopedEvents: [StatEvent] {
        guard !periodFilter.isEmpty else { return gameEvents }
        return gameEvents.filter { periodFilter.contains($0.period) }
    }

    private var myPlayers: [Player] {
        guard let teamID = game.myTeamID else { return [] }
        return allPlayers
            .filter { $0.teamID == teamID }
            .sorted { (Int($0.jerseyNumber) ?? 999) < (Int($1.jerseyNumber) ?? 999) }
    }

    private var opponentPlayers: [Player] {
        guard let teamID = game.opponentTeamID else { return [] }
        return allPlayers
            .filter { $0.teamID == teamID }
            .sorted { (Int($0.jerseyNumber) ?? 999) < (Int($1.jerseyNumber) ?? 999) }
    }

    private var hasOpponentPlayers: Bool {
        game.opponentTrackingLevel == .individual && !opponentPlayers.isEmpty
    }

    /// First five by jersey number — the closest proxy for a starting five
    /// (Courtside has no explicit starter flag).
    private var starterIDs: Set<UUID> {
        Set(myPlayers.prefix(5).map(\.id))
    }

    private var displayedPlayers: [Player] {
        let base = teamSide == .mine ? myPlayers : opponentPlayers
        guard teamSide == .mine else { return base }
        switch lineupFilter {
        case .all:      return base
        case .starters: return base.filter { starterIDs.contains($0.id) }
        case .bench:    return base.filter { !starterIDs.contains($0.id) }
        }
    }

    private func line(for player: Player) -> BoxScoreLine {
        if teamSide == .opponent {
            return opponentLine(for: player)
        }
        return StatCalculator.boxScoreLine(
            for: player,
            from: scopedEvents,
            periods: nil
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            filterChips

            ScrollView {
                VStack(spacing: 4) {
                    headerRow
                    if teamSide == .opponent && !hasOpponentPlayers {
                        teamOnlyOpponentRow
                    } else {
                        ForEach(displayedPlayers, id: \.id) { player in
                            playerRow(player)
                        }
                        if displayedPlayers.isEmpty {
                            Text("No players to show.")
                                .font(.csUI(13))
                                .foregroundStyle(CS.inkMute)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                        }
                    }
                    totalRow
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)

            if teamSide == .mine { leadersFooter }
        }
        .background(CS.bgStage)
        .sheet(item: $editTarget) { target in
            BoxScoreEditSheet(
                game: game,
                player: target.player,
                cell: .allStats,
                isOpponent: target.isOpponent
            )
        }
    }

    // MARK: - Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                chip(game.myTeamID != nil ? "My Team" : "Team",
                     selected: teamSide == .mine, dot: CS.home) {
                    teamSide = .mine
                }
                if hasOpponentPlayers || game.opponentTrackingLevel != .none {
                    chip(game.opponentName.isEmpty ? "Opponent" : game.opponentName,
                         selected: teamSide == .opponent, dot: CS.away) {
                        teamSide = .opponent
                    }
                }

                Divider().frame(height: 18)

                chip("All", selected: lineupFilter == .all) { lineupFilter = .all }
                chip("Starters", selected: lineupFilter == .starters) { lineupFilter = .starters }
                chip("Bench", selected: lineupFilter == .bench) { lineupFilter = .bench }

                Divider().frame(height: 18)

                ForEach(1...game.format.periodCount, id: \.self) { period in
                    chip(game.format.periodLabel(for: period),
                         selected: periodFilter.contains(period)) {
                        if periodFilter.contains(period) {
                            periodFilter.remove(period)
                        } else {
                            periodFilter.insert(period)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(_ label: String, selected: Bool,
                      dot: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let dot {
                    Circle().fill(dot).frame(width: 6, height: 6)
                }
                Text(label)
            }
            .font(.csUI(12, weight: .bold))
            .foregroundStyle(selected ? .white : CS.inkMute)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? CS.ink : CS.bgSoft, in: Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 6) {
            Text("PLAYER")
                .frame(width: 104, alignment: .leading)
            Text("FG · 3PT · FT")
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text("REB·AST·STL")
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text("BLK·TO·PF")
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text("PTS")
                .frame(width: 40, alignment: .trailing)
        }
        .font(.csUI(9, weight: .bold))
        .tracking(0.8)
        .foregroundStyle(CS.inkDim)
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CS.line).frame(height: 1)
        }
    }

    // MARK: - Player row

    private func playerRow(_ player: Player) -> some View {
        let l = line(for: player)
        let isStarter = teamSide == .mine && starterIDs.contains(player.id)
        return Button {
            editTarget = EditTarget(player: player, isOpponent: teamSide == .opponent)
        } label: {
            HStack(spacing: 6) {
                HStack(spacing: 6) {
                    Jersey(number: player.jerseyNumber,
                           color: teamSide == .mine ? CS.home : CS.away, size: 22)
                    Text(player.lastName.isEmpty ? player.fullName : player.lastName)
                        .font(.csUI(13, weight: .bold))
                        .foregroundStyle(CS.ink)
                        .lineLimit(1)
                }
                .frame(width: 104, alignment: .leading)

                statGroup(strong: shot(l.fieldGoalsMade, l.fieldGoalsAttempted),
                          rest: ["\(l.threePointMade)/\(l.threePointAttempted)",
                                 "\(l.freeThrowsMade)/\(l.freeThrowsAttempted)"])
                statGroup(strong: "\(l.totalRebounds)",
                          rest: ["\(l.assists)", "\(l.steals)"])
                statGroup(strong: "\(l.blocks)",
                          rest: ["\(l.turnovers)"], foul: l.fouls)

                Text("\(l.points)")
                    .font(.csDisplay(22, weight: .heavy))
                    .foregroundStyle(CS.ink)
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(isStarter ? CS.bgCard : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isStarter ? CS.line : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// A grouped stat cell: the first value is inked, the rest muted.
    /// `foul` (when set) is appended last and turns amber at 4+.
    private func statGroup(strong: String, rest: [String], foul: Int? = nil) -> some View {
        HStack(spacing: 3) {
            Text(strong).foregroundStyle(CS.ink)
            ForEach(Array(rest.enumerated()), id: \.offset) { _, value in
                Text("·").foregroundStyle(CS.inkDim)
                Text(value).foregroundStyle(CS.inkMute)
            }
            if let foul {
                Text("·").foregroundStyle(CS.inkDim)
                Text("\(foul)")
                    .foregroundStyle(foul >= 4 ? CS.amber : CS.inkMute)
                    .fontWeight(foul >= 4 ? .bold : .regular)
            }
        }
        .font(.csMono(11))
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func shot(_ made: Int, _ attempted: Int) -> String {
        "\(made)/\(attempted)"
    }

    // MARK: - Total / opponent rows

    private var totalRow: some View {
        let l = StatCalculator.teamBoxScoreLine(
            from: scopedEvents,
            isOpponent: teamSide == .opponent
        )
        return HStack(spacing: 6) {
            Text("TOTAL")
                .font(.csUI(11, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(CS.ink)
                .frame(width: 104, alignment: .leading)
            Text("\(l.fieldGoalsMade)/\(l.fieldGoalsAttempted) · \(l.threePointMade)/\(l.threePointAttempted) · \(l.freeThrowsMade)/\(l.freeThrowsAttempted)")
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text("\(l.totalRebounds) · \(l.assists) · \(l.steals)")
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text("\(l.blocks) · \(l.turnovers) · \(l.fouls)")
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text("\(l.points)")
                .font(.csDisplay(24, weight: .heavy))
                .foregroundStyle(teamSide == .mine ? CS.home : CS.away)
                .frame(width: 40, alignment: .trailing)
        }
        .font(.csMono(11, weight: .semibold))
        .foregroundStyle(CS.ink)
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .overlay(alignment: .top) {
            Rectangle().fill(CS.ink).frame(height: 1.4)
        }
        .padding(.top, 6)
    }

    private var teamOnlyOpponentRow: some View {
        let l = StatCalculator.teamBoxScoreLine(from: scopedEvents, isOpponent: true)
        return Button {
            editTarget = EditTarget(player: nil, isOpponent: true)
        } label: {
            HStack {
                Text(game.opponentName.isEmpty ? "Opponent" : game.opponentName)
                    .font(.csUI(13, weight: .bold))
                Spacer()
                Text("Team-level tracking · tap to edit")
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkMute)
                Text("\(l.points)")
                    .font(.csDisplay(22, weight: .heavy))
            }
            .foregroundStyle(CS.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background(CS.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(CS.line, lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Leaders footer

    private var leadersFooter: some View {
        let lines = myPlayers.map { ($0, StatCalculator.boxScoreLine(for: $0, from: gameEvents)) }
        let pts = lines.max { $0.1.points < $1.1.points }
        let reb = lines.max { $0.1.totalRebounds < $1.1.totalRebounds }
        let ast = lines.max { $0.1.assists < $1.1.assists }
        return HStack(spacing: 8) {
            leaderChip("PTS", value: pts?.1.points ?? 0, player: pts?.0)
            leaderChip("REB", value: reb?.1.totalRebounds ?? 0, player: reb?.0)
            leaderChip("AST", value: ast?.1.assists ?? 0, player: ast?.0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(CS.bgCard)
        .overlay(alignment: .top) {
            Rectangle().fill(CS.line).frame(height: 1)
        }
    }

    private func leaderChip(_ label: String, value: Int, player: Player?) -> some View {
        HStack(spacing: 8) {
            Text("\(value)")
                .font(.csDisplay(22, weight: .heavy))
                .foregroundStyle(CS.ink)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.csUI(9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(CS.inkDim)
                Text(player.map { "#\($0.jerseyNumber) \($0.lastName)" } ?? "—")
                    .font(.csUI(11, weight: .bold))
                    .foregroundStyle(CS.ink)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(CS.bgStage)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CS.line, lineWidth: 1))
    }

    // MARK: - Helpers

    private func opponentLine(for player: Player) -> BoxScoreLine {
        let events = scopedEvents.filter {
            $0.isOpponentStat && $0.playerID == player.id
        }
        var line = BoxScoreLine()
        for event in events {
            switch event.statType {
            case .fieldGoalMade:
                line.fieldGoalsMade += 1; line.fieldGoalsAttempted += 1; line.points += 2
            case .fieldGoalMissed:
                line.fieldGoalsAttempted += 1
            case .threePointMade:
                line.threePointMade += 1; line.threePointAttempted += 1
                line.fieldGoalsMade += 1; line.fieldGoalsAttempted += 1; line.points += 3
            case .threePointMissed:
                line.threePointAttempted += 1; line.fieldGoalsAttempted += 1
            case .freeThrowMade:
                line.freeThrowsMade += 1; line.freeThrowsAttempted += 1; line.points += 1
            case .freeThrowMissed:
                line.freeThrowsAttempted += 1
            case .offensiveRebound: line.offensiveRebounds += 1
            case .defensiveRebound: line.defensiveRebounds += 1
            case .assist:           line.assists += 1
            case .turnover:         line.turnovers += 1
            case .steal:            line.steals += 1
            case .block:            line.blocks += 1
            case .foul:             line.fouls += 1
            }
        }
        return line
    }
}
