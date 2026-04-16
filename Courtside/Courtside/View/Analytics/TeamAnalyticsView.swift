import SwiftUI
import SwiftData

// MARK: - Filter mode

enum AnalyticsFilterMode: String, CaseIterable {
    case allGames    = "All"
    case singleGame  = "Game"
    case dateRange   = "Date Range"
}

// MARK: - Analytics view

/// Analytics hub for a team — currently houses the shot chart with game-filter controls.
/// Structured so future analytics sections (assists, rebounding, trends) can be added below.
struct TeamAnalyticsView: View {
    let team: Team

    @Environment(\.theme) private var theme

    @Query private var allGames: [Game]
    @Query private var allEvents: [StatEvent]
    @Query private var allPlayers: [Player]

    @State private var filterMode: AnalyticsFilterMode = .allGames
    @State private var selectedGameID: UUID?
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var endDate: Date = Date()

    // MARK: - Derived data

    private var teamGames: [Game] {
        allGames
            .filter { $0.myTeamID == team.id && $0.isComplete }
            .sorted { $0.date > $1.date }
    }

    private var teamPlayers: [Player] {
        allPlayers.filter { $0.teamID == team.id && $0.isActive }
    }

    private var opponentPlayers: [Player] {
        let opponentTeamIDs = Set(filteredGames.compactMap(\.opponentTeamID))
        return allPlayers.filter { p in
            guard let tid = p.teamID else { return false }
            return opponentTeamIDs.contains(tid)
        }
    }

    private var filteredGames: [Game] {
        switch filterMode {
        case .allGames:
            return teamGames
        case .singleGame:
            let targetID = selectedGameID ?? teamGames.first?.id
            return teamGames.filter { $0.id == targetID }
        case .dateRange:
            let startOfStart = Calendar.current.startOfDay(for: startDate)
            let endOfEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
            return teamGames.filter { $0.date >= startOfStart && $0.date <= endOfEnd }
        }
    }

    private var filteredEvents: [StatEvent] {
        let gameIDs = Set(filteredGames.map(\.id))
        return allEvents.filter { event in
            guard let gid = event.gameID else { return false }
            return gameIDs.contains(gid)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                filterSection

                Divider()

                shotChartSection
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .background(theme.background)
    }

    // MARK: - Filter controls

    private var filterSection: some View {
        VStack(spacing: 12) {
            Picker("Filter", selection: $filterMode) {
                ForEach(AnalyticsFilterMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            switch filterMode {
            case .allGames:
                EmptyView()

            case .singleGame:
                if teamGames.isEmpty {
                    Text("No completed games yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                } else {
                    Picker("Game", selection: $selectedGameID) {
                        ForEach(teamGames) { game in
                            Text("vs \(game.opponentName) · \(game.date.formatted(date: .abbreviated, time: .omitted))")
                                .tag(Optional<UUID>.some(game.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            case .dateRange:
                VStack(spacing: 8) {
                    DatePicker("From", selection: $startDate, in: ...endDate, displayedComponents: .date)
                    DatePicker("To",   selection: $endDate,   in: startDate..., displayedComponents: .date)
                }
                .padding(.horizontal)
            }

            // Game count summary
            if !filteredGames.isEmpty {
                Text(filterMode == .allGames
                     ? "\(filteredGames.count) game\(filteredGames.count == 1 ? "" : "s")"
                     : "\(filteredGames.count) game\(filteredGames.count == 1 ? "" : "s") selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Shot chart section

    private var shotChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shot Chart")
                .font(.headline)
                .padding(.horizontal)

            if teamGames.isEmpty {
                ContentUnavailableView(
                    "No games yet",
                    systemImage: "basketball",
                    description: Text("Complete a game to see shot charts here.")
                )
                .padding()
            } else {
                ShotChartSectionView(
                    events: filteredEvents,
                    myPlayers: teamPlayers,
                    opponentPlayers: opponentPlayers
                )
                .padding(.horizontal)
            }
        }
    }
}
