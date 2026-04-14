import SwiftUI
import SwiftData

struct BoxScoreView: View {
    let game: Game
    @Environment(\.theme) private var theme
    @Query private var allEvents: [StatEvent]
    @Query private var allPlayers: [Player]

    @State private var showingOpponent = false
    @State private var editTarget: EditTarget?

    private struct EditTarget: Identifiable {
        let id = UUID()
        let player: Player?
        let cell: BoxScoreCell
        let isOpponent: Bool
    }

    private var gameEvents: [StatEvent] {
        allEvents.filter { $0.gameID == game.id && !$0.isDeleted }
    }

    private var myPlayers: [Player] {
        guard let teamID = game.myTeamID else { return [] }
        return allPlayers.filter { $0.teamID == teamID }
    }

    private var opponentPlayers: [Player] {
        guard let teamID = game.opponentTeamID else { return [] }
        return allPlayers.filter { $0.teamID == teamID }
    }

    private var hasOpponentPlayers: Bool {
        game.opponentTrackingLevel == .individual && !opponentPlayers.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Team toggle (if tracking opponent individuals)
            if hasOpponentPlayers {
                Picker("Team", selection: $showingOpponent) {
                    Text("My Team").tag(false)
                    Text(game.opponentName).tag(true)
                }
                .pickerStyle(.segmented)
                .padding()
            }

            // Box score table
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header row
                    headerRow

                    Divider()

                    // Player rows
                    let players = showingOpponent ? opponentPlayers : myPlayers
                    let isOpp = showingOpponent

                    ForEach(players.sorted(by: {
                        (Int($0.jerseyNumber) ?? 999) < (Int($1.jerseyNumber) ?? 999)
                    })) { player in
                        let line = StatCalculator.boxScoreLine(
                            for: player,
                            from: isOpp ? gameEvents.filter { $0.isOpponentStat } : gameEvents
                        )
                        // Only show players who have at least one stat
                        if line.points > 0 || line.totalRebounds > 0 || line.assists > 0 ||
                           line.turnovers > 0 || line.steals > 0 || line.blocks > 0 ||
                           line.fouls > 0 || line.fieldGoalsAttempted > 0 {
                            playerRow(player: player, line: line, isOpponent: isOpp)
                            Divider()
                        }
                    }

                    // Also show players with zero stats (dimmed)
                    let activePlayers = players.sorted(by: {
                        (Int($0.jerseyNumber) ?? 999) < (Int($1.jerseyNumber) ?? 999)
                    })
                    ForEach(activePlayers) { player in
                        let line = isOpp
                            ? boxLineForOpponentPlayer(player)
                            : StatCalculator.boxScoreLine(for: player, from: gameEvents)
                        let hasStats = line.points > 0 || line.totalRebounds > 0 || line.assists > 0 ||
                            line.turnovers > 0 || line.steals > 0 || line.blocks > 0 ||
                            line.fouls > 0 || line.fieldGoalsAttempted > 0
                        if !hasStats {
                            playerRow(player: player, line: line, isOpponent: isOpp, dimmed: true)
                            Divider()
                        }
                    }

                    // Totals row
                    totalsRow(isOpponent: isOpp)
                }
            }
        }
        .navigationTitle("Box Score")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editTarget) { target in
            BoxScoreEditSheet(
                game: game,
                player: target.player,
                cell: target.cell,
                isOpponent: target.isOpponent
            )
        }
        .onAppear {
            OrientationManager.shared.allowLandscape = true
        }
        .onDisappear {
            OrientationManager.shared.allowLandscape = false
            // Force back to portrait when leaving
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("Player")
                .frame(width: 100, alignment: .leading)
            statHeader("PTS")
            statHeader("FG")
            statHeader("3PT")
            statHeader("FT")
            statHeader("REB")
            statHeader("AST")
            statHeader("TO")
            statHeader("STL")
            statHeader("BLK")
            statHeader("PF")
        }
        .font(.caption2.bold())
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.secondaryBackground)
    }

    private func statHeader(_ text: String) -> some View {
        Text(text)
            .frame(width: 44, alignment: .center)
    }

    // MARK: - Player Row

    private func playerRow(player: Player, line: BoxScoreLine, isOpponent: Bool, dimmed: Bool = false) -> some View {
        HStack(spacing: 0) {
            Button {
                editTarget = EditTarget(player: player, cell: .allStats, isOpponent: isOpponent)
            } label: {
                HStack(spacing: 4) {
                    Text("#\(player.jerseyNumber)")
                        .fontWeight(.bold)
                        .frame(width: 30, alignment: .leading)
                    Text(player.shortName)
                        .lineLimit(1)
                }
                .frame(width: 100, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            tappableStatCell("\(line.points)", player: player, cell: .points, isOpponent: isOpponent, highlight: line.points > 0)
            tappableStatCell(shotString(line.fieldGoalsMade, line.fieldGoalsAttempted), player: player, cell: .fieldGoals, isOpponent: isOpponent)
            tappableStatCell(shotString(line.threePointMade, line.threePointAttempted), player: player, cell: .threePoints, isOpponent: isOpponent)
            tappableStatCell(shotString(line.freeThrowsMade, line.freeThrowsAttempted), player: player, cell: .freeThrows, isOpponent: isOpponent)
            tappableStatCell("\(line.totalRebounds)", player: player, cell: .rebounds, isOpponent: isOpponent)
            tappableStatCell("\(line.assists)", player: player, cell: .assists, isOpponent: isOpponent)
            tappableStatCell("\(line.turnovers)", player: player, cell: .turnovers, isOpponent: isOpponent)
            tappableStatCell("\(line.steals)", player: player, cell: .steals, isOpponent: isOpponent)
            tappableStatCell("\(line.blocks)", player: player, cell: .blocks, isOpponent: isOpponent)
            tappableStatCell("\(line.fouls)", player: player, cell: .fouls, isOpponent: isOpponent)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .opacity(dimmed ? 0.4 : 1.0)
    }

    private func tappableStatCell(_ text: String, player: Player?, cell: BoxScoreCell, isOpponent: Bool, highlight: Bool = false) -> some View {
        Button {
            editTarget = EditTarget(player: player, cell: cell, isOpponent: isOpponent)
        } label: {
            Text(text)
                .fontWeight(highlight ? .semibold : .regular)
                .frame(width: 44, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func statCell(_ text: String, highlight: Bool = false) -> some View {
        Text(text)
            .fontWeight(highlight ? .semibold : .regular)
            .frame(width: 44, alignment: .center)
    }

    private func shotString(_ made: Int, _ attempted: Int) -> String {
        "\(made)/\(attempted)"
    }

    // MARK: - Totals Row

    private func totalsRow(isOpponent: Bool) -> some View {
        let line = StatCalculator.teamBoxScoreLine(
            from: gameEvents,
            isOpponent: isOpponent
        )

        // Per design: opponent totals are editable only when no individual rows exist
        // (team-level opponent tracking). Otherwise edit at the player rows.
        let totalsEditable: Bool = {
            if !isOpponent { return true }
            return !hasOpponentPlayers
        }()

        return HStack(spacing: 0) {
            Text("TOTAL")
                .fontWeight(.bold)
                .frame(width: 100, alignment: .leading)

            totalCell("\(line.points)", cell: .points, isOpponent: isOpponent, editable: totalsEditable, highlight: true)
            totalCell(shotString(line.fieldGoalsMade, line.fieldGoalsAttempted), cell: .fieldGoals, isOpponent: isOpponent, editable: totalsEditable)
            totalCell(shotString(line.threePointMade, line.threePointAttempted), cell: .threePoints, isOpponent: isOpponent, editable: totalsEditable)
            totalCell(shotString(line.freeThrowsMade, line.freeThrowsAttempted), cell: .freeThrows, isOpponent: isOpponent, editable: totalsEditable)
            totalCell("\(line.totalRebounds)", cell: .rebounds, isOpponent: isOpponent, editable: totalsEditable)
            totalCell("\(line.assists)", cell: .assists, isOpponent: isOpponent, editable: totalsEditable)
            totalCell("\(line.turnovers)", cell: .turnovers, isOpponent: isOpponent, editable: totalsEditable)
            totalCell("\(line.steals)", cell: .steals, isOpponent: isOpponent, editable: totalsEditable)
            totalCell("\(line.blocks)", cell: .blocks, isOpponent: isOpponent, editable: totalsEditable)
            totalCell("\(line.fouls)", cell: .fouls, isOpponent: isOpponent, editable: totalsEditable)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.secondaryBackground)
    }

    @ViewBuilder
    private func totalCell(_ text: String, cell: BoxScoreCell, isOpponent: Bool, editable: Bool, highlight: Bool = false) -> some View {
        if editable {
            tappableStatCell(text, player: nil, cell: cell, isOpponent: isOpponent, highlight: highlight)
        } else {
            statCell(text, highlight: highlight)
        }
    }

    // MARK: - Helpers

    private func boxLineForOpponentPlayer(_ player: Player) -> BoxScoreLine {
        let events = gameEvents.filter { $0.isOpponentStat && $0.playerID == player.id && !$0.isDeleted }
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
            case .assist: line.assists += 1
            case .turnover: line.turnovers += 1
            case .steal: line.steals += 1
            case .block: line.blocks += 1
            case .foul: line.fouls += 1
            }
        }
        return line
    }
}
