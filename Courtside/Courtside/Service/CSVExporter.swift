import Foundation
import SwiftData

enum CSVExporter {

    /// Generates a CSV string for a game's box score
    static func exportBoxScore(
        game: Game,
        myTeamName: String,
        players: [Player],
        opponentPlayers: [Player],
        events: [StatEvent]
    ) -> String {
        var lines: [String] = []

        // Header info
        lines.append("Game Summary")
        lines.append("\(myTeamName) vs \(game.opponentName)")
        lines.append("Date,\(formatDate(game.date))")
        lines.append("Final Score,\(game.myTeamScore) - \(game.opponentScore)")
        lines.append("")

        // Period scores
        if game.isComplete {
            var periodHeaders = ["Team"]
            var myScores = [myTeamName]
            var oppScores = [game.opponentName]
            for period in 1...game.currentPeriod {
                periodHeaders.append(game.format.periodLabel(for: period))
                myScores.append("\(game.scoreForPeriod(period, isOpponent: false))")
                oppScores.append("\(game.scoreForPeriod(period, isOpponent: true))")
            }
            periodHeaders.append("Total")
            myScores.append("\(game.myTeamScore)")
            oppScores.append("\(game.opponentScore)")

            lines.append(periodHeaders.joined(separator: ","))
            lines.append(myScores.joined(separator: ","))
            lines.append(oppScores.joined(separator: ","))
            lines.append("")
        }

        // My team box score
        lines.append("\(myTeamName) Box Score")
        lines.append(boxScoreHeader())

        let myEvents = events.filter { !$0.isOpponentStat && !$0.isDeleted }
        for player in sortedPlayers(players) {
            let line = StatCalculator.boxScoreLine(for: player, from: myEvents)
            lines.append(playerCSVRow(player: player, line: line))
        }

        let myTotals = StatCalculator.teamBoxScoreLine(from: events, isOpponent: false)
        lines.append(totalsCSVRow(line: myTotals))
        lines.append("")

        // Opponent box score (if individual tracking)
        if game.opponentTrackingLevel == .individual && !opponentPlayers.isEmpty {
            lines.append("\(game.opponentName) Box Score")
            lines.append(boxScoreHeader())

            let oppEvents = events.filter { $0.isOpponentStat && !$0.isDeleted }
            for player in sortedPlayers(opponentPlayers) {
                let line = StatCalculator.boxScoreLine(for: player, from: oppEvents)
                lines.append(playerCSVRow(player: player, line: line))
            }

            let oppTotals = StatCalculator.teamBoxScoreLine(from: events, isOpponent: true)
            lines.append(totalsCSVRow(line: oppTotals))
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// Writes CSV to a temporary file and returns the URL
    static func writeToFile(
        csv: String,
        myTeamName: String,
        opponentName: String,
        date: Date
    ) -> URL? {
        let dateStr = formatDate(date).replacingOccurrences(of: "/", with: "-")
        let fileName = "\(myTeamName)_vs_\(opponentName)_\(dateStr).csv"
            .replacingOccurrences(of: " ", with: "_")

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }

    // MARK: - Helpers

    private static func boxScoreHeader() -> String {
        "Player,#,PTS,FGM,FGA,FG%,3PM,3PA,3P%,FTM,FTA,FT%,OREB,DREB,REB,AST,TO,STL,BLK,PF"
    }

    private static func playerCSVRow(player: Player, line: BoxScoreLine) -> String {
        [
            escapeCSV(player.fullName),
            player.jerseyNumber,
            "\(line.points)",
            "\(line.fieldGoalsMade)",
            "\(line.fieldGoalsAttempted)",
            StatCalculator.formatPercentage(line.fieldGoalPercentage),
            "\(line.threePointMade)",
            "\(line.threePointAttempted)",
            StatCalculator.formatPercentage(line.threePointPercentage),
            "\(line.freeThrowsMade)",
            "\(line.freeThrowsAttempted)",
            StatCalculator.formatPercentage(line.freeThrowPercentage),
            "\(line.offensiveRebounds)",
            "\(line.defensiveRebounds)",
            "\(line.totalRebounds)",
            "\(line.assists)",
            "\(line.turnovers)",
            "\(line.steals)",
            "\(line.blocks)",
            "\(line.fouls)",
        ].joined(separator: ",")
    }

    private static func totalsCSVRow(line: BoxScoreLine) -> String {
        [
            "TOTAL",
            "",
            "\(line.points)",
            "\(line.fieldGoalsMade)",
            "\(line.fieldGoalsAttempted)",
            StatCalculator.formatPercentage(line.fieldGoalPercentage),
            "\(line.threePointMade)",
            "\(line.threePointAttempted)",
            StatCalculator.formatPercentage(line.threePointPercentage),
            "\(line.freeThrowsMade)",
            "\(line.freeThrowsAttempted)",
            StatCalculator.formatPercentage(line.freeThrowPercentage),
            "\(line.offensiveRebounds)",
            "\(line.defensiveRebounds)",
            "\(line.totalRebounds)",
            "\(line.assists)",
            "\(line.turnovers)",
            "\(line.steals)",
            "\(line.blocks)",
            "\(line.fouls)",
        ].joined(separator: ",")
    }

    private static func sortedPlayers(_ players: [Player]) -> [Player] {
        players.sorted { (Int($0.jerseyNumber) ?? 999) < (Int($1.jerseyNumber) ?? 999) }
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private static func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }
}
