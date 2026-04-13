import SwiftUI
import SwiftData

struct BoxScoreView: View {
    let game: Game
    @Query private var allEvents: [StatEvent]
    @Query private var allPlayers: [Player]

    @State private var showingOpponent = false

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
                            playerRow(player: player, line: line)
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
                            playerRow(player: player, line: line, dimmed: true)
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
        .background(Color(.systemGray6))
    }

    private func statHeader(_ text: String) -> some View {
        Text(text)
            .frame(width: 44, alignment: .center)
    }

    // MARK: - Player Row

    private func playerRow(player: Player, line: BoxScoreLine, dimmed: Bool = false) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Text("#\(player.jerseyNumber)")
                    .fontWeight(.bold)
                    .frame(width: 30, alignment: .leading)
                Text(player.shortName)
                    .lineLimit(1)
            }
            .frame(width: 100, alignment: .leading)

            statCell("\(line.points)", highlight: line.points > 0)
            statCell(shotString(line.fieldGoalsMade, line.fieldGoalsAttempted))
            statCell(shotString(line.threePointMade, line.threePointAttempted))
            statCell(shotString(line.freeThrowsMade, line.freeThrowsAttempted))
            statCell("\(line.totalRebounds)")
            statCell("\(line.assists)")
            statCell("\(line.turnovers)")
            statCell("\(line.steals)")
            statCell("\(line.blocks)")
            statCell("\(line.fouls)")
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .opacity(dimmed ? 0.4 : 1.0)
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

        return HStack(spacing: 0) {
            Text("TOTAL")
                .fontWeight(.bold)
                .frame(width: 100, alignment: .leading)

            statCell("\(line.points)", highlight: true)
            statCell(shotString(line.fieldGoalsMade, line.fieldGoalsAttempted))
            statCell(shotString(line.threePointMade, line.threePointAttempted))
            statCell(shotString(line.freeThrowsMade, line.freeThrowsAttempted))
            statCell("\(line.totalRebounds)")
            statCell("\(line.assists)")
            statCell("\(line.turnovers)")
            statCell("\(line.steals)")
            statCell("\(line.blocks)")
            statCell("\(line.fouls)")
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
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
