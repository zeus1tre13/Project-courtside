import SwiftUI
import SwiftData

/// Light-touch team analytics — season averages, a season heat map, and
/// leaders. Deliberately compact: the deep cuts live on XCIV.ai, surfaced
/// through the upgrade card at the bottom.
struct TeamAnalyticsView: View {
    let team: Team

    @Query private var allGames: [Game]
    @Query private var allEvents: [StatEvent]
    @Query private var allPlayers: [Player]

    @State private var scope: AnalyticsScope = .allGames
    @State private var selectedGameID: UUID?
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var endDate = Date()

    enum AnalyticsScope: String, CaseIterable {
        case allGames = "All games"
        case thisSeason = "This season"
        case last5 = "Last 5"
        case singleGame = "Single game"
        case dateRange = "Date range"
    }

    // MARK: - Derived data

    private var teamGames: [Game] {
        allGames
            .filter { $0.myTeamID == team.id && $0.isComplete }
            .sorted { $0.date > $1.date }
    }

    private var teamPlayers: [Player] {
        allPlayers
            .filter { $0.teamID == team.id && $0.isActive }
            .sorted { (Int($0.jerseyNumber) ?? 999) < (Int($1.jerseyNumber) ?? 999) }
    }

    private var filteredGames: [Game] {
        switch scope {
        case .allGames:
            return teamGames
        case .thisSeason:
            let year = Calendar.current.component(.year, from: Date())
            return teamGames.filter { Calendar.current.component(.year, from: $0.date) == year }
        case .last5:
            return Array(teamGames.prefix(5))
        case .singleGame:
            let targetID = selectedGameID ?? teamGames.first?.id
            return teamGames.filter { $0.id == targetID }
        case .dateRange:
            let start = Calendar.current.startOfDay(for: startDate)
            let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
            return teamGames.filter { $0.date >= start && $0.date <= end }
        }
    }

    private var filteredEvents: [StatEvent] {
        let gameIDs = Set(filteredGames.map(\.id))
        return allEvents.filter { event in
            guard let gid = event.gameID else { return false }
            return gameIDs.contains(gid) && !event.isDeleted
        }
    }

    private var gameCount: Int { filteredGames.count }
    private var wins: Int { filteredGames.filter { $0.myTeamScore > $0.opponentScore }.count }
    private var losses: Int { filteredGames.filter { $0.myTeamScore < $0.opponentScore }.count }

    private var teamLine: BoxScoreLine {
        StatCalculator.teamBoxScoreLine(from: filteredEvents, isOpponent: false)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                scopePills
                recordLine

                if gameCount == 0 {
                    emptyState
                } else {
                    averages
                    heatMapSection
                    leaders
                }

                xcivCard
            }
            .padding(.vertical, 14)
        }
        .background(CS.bgStage)
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Scope

    private var scopePills: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(AnalyticsScope.allCases, id: \.self) { item in
                        Button {
                            scope = item
                        } label: {
                            Text(item.rawValue)
                                .font(.csUI(12, weight: .bold))
                                .foregroundStyle(scope == item ? .white : CS.inkMute)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(scope == item ? CS.ink : CS.bgSoft, in: Capsule())
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 14)
            }
            .scrollIndicators(.hidden)

            scopeDetail
        }
    }

    @ViewBuilder
    private var scopeDetail: some View {
        switch scope {
        case .singleGame where !teamGames.isEmpty:
            Picker("Game", selection: $selectedGameID) {
                ForEach(teamGames) { game in
                    Text("vs \(game.opponentName) · \(game.date.formatted(date: .abbreviated, time: .omitted))")
                        .tag(Optional(game.id))
                }
            }
            .tint(CS.brand)
            .padding(.horizontal, 14)
        case .dateRange:
            VStack(spacing: 6) {
                DatePicker("From", selection: $startDate, in: ...endDate, displayedComponents: .date)
                DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: .date)
            }
            .font(.csUI(13))
            .tint(CS.brand)
            .padding(.horizontal, 14)
        default:
            EmptyView()
        }
    }

    private var recordLine: some View {
        Text(gameCount == 0
             ? "No completed games in this range"
             : "\(gameCount) game\(gameCount == 1 ? "" : "s") · \(wins)-\(losses) record")
            .font(.csMono(11))
            .foregroundStyle(CS.inkMute)
            .padding(.horizontal, 14)
    }

    // MARK: - Averages

    private var averages: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TEAM AVERAGES")
            HStack(spacing: 6) {
                avgChip(perGame(teamLine.points), "PPG")
                avgChip(percent(teamLine.fieldGoalPercentage), "FG")
                avgChip(percent(teamLine.threePointPercentage), "3PT")
                avgChip(perGame(teamLine.totalRebounds), "RPG")
            }
            .padding(.horizontal, 14)
        }
    }

    private func avgChip(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.csDisplay(22, weight: .heavy))
                .foregroundStyle(CS.ink)
            Text(label)
                .font(.csUI(9, weight: .bold))
                .tracking(1)
                .foregroundStyle(CS.inkDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CS.line, lineWidth: 1))
    }

    // MARK: - Heat map

    private var heatMapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("HOT & COLD ZONES · \(scope.rawValue.uppercased())")
            let data = ShotChartCalculator.compute(from: filteredEvents, isOpponent: false)
            Group {
                if data.isEmpty {
                    Text("No shots with a recorded zone in this range.")
                        .font(.csUI(12))
                        .foregroundStyle(CS.inkMute)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                } else {
                    ShotHeatCourt(data: data)
                }
            }
            .padding(10)
            .background(CS.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
            .padding(.horizontal, 14)
        }
    }

    // MARK: - Leaders

    private var leaders: some View {
        let lines = teamPlayers.map { ($0, StatCalculator.boxScoreLine(for: $0, from: filteredEvents)) }
        let ppg = lines.max { $0.1.points < $1.1.points }
        let rpg = lines.max { $0.1.totalRebounds < $1.1.totalRebounds }
        let apg = lines.max { $0.1.assists < $1.1.assists }
        return VStack(alignment: .leading, spacing: 8) {
            sectionLabel("SEASON LEADERS")
            VStack(spacing: 6) {
                if let ppg, ppg.1.points > 0 {
                    leaderRow(ppg.0, label: "PPG", value: perGame(ppg.1.points))
                }
                if let rpg, rpg.1.totalRebounds > 0 {
                    leaderRow(rpg.0, label: "RPG", value: perGame(rpg.1.totalRebounds))
                }
                if let apg, apg.1.assists > 0 {
                    leaderRow(apg.0, label: "APG", value: perGame(apg.1.assists))
                }
            }
            .padding(.horizontal, 14)
        }
    }

    private func leaderRow(_ player: Player, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Jersey(number: player.jerseyNumber, color: CS.home, size: 32)
            Text(player.lastName.isEmpty ? player.fullName : player.lastName)
                .font(.csUI(13, weight: .bold))
                .foregroundStyle(CS.ink)
            Spacer()
            Text(value)
                .font(.csDisplay(20, weight: .heavy))
                .foregroundStyle(CS.ink)
            Text(label)
                .font(.csUI(9, weight: .bold))
                .tracking(1)
                .foregroundStyle(CS.inkDim)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CS.line, lineWidth: 1))
    }

    // MARK: - XCIV upgrade card

    private var xcivCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("★ COACH-GRADE")
                .font(.csDisplay(11, weight: .heavy))
                .tracking(2)
                .foregroundStyle(CS.amber)

            (Text("Go deeper on\n").foregroundStyle(.white)
             + Text("XCIV.ai").foregroundStyle(CS.amber))
                .font(.csDisplay(26, weight: .heavy))

            Text("Lineup +/−, opponent scouting, possession-by-possession breakdowns, trend forecasts and AI insights — built on your Courtside data.")
                .font(.csUI(13))
                .foregroundStyle(.white.opacity(0.75))

            HStack(spacing: 10) {
                Link(destination: URL(string: "https://xciv.ai")!) {
                    Text("TRY FREE →")
                        .font(.csUI(13, weight: .heavy))
                        .tracking(0.6)
                        .foregroundStyle(CS.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(CS.amber, in: Capsule())
                }
                Text("14-day trial · no card")
                    .font(.csUI(11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [CS.ink2, CS.ink],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "basketball")
                .font(.system(size: 34))
                .foregroundStyle(CS.inkDim)
            Text("No completed games yet")
                .font(.csDisplay(18, weight: .bold))
                .foregroundStyle(CS.ink)
            Text("Finish a game to see season averages and zones here.")
                .font(.csUI(13))
                .foregroundStyle(CS.inkMute)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.csUI(11, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(CS.inkDim)
            .padding(.horizontal, 14)
    }

    private func perGame(_ total: Int) -> String {
        guard gameCount > 0 else { return "—" }
        return String(format: "%.1f", Double(total) / Double(gameCount))
    }

    private func percent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value * 100))%"
    }
}
