import SwiftUI
import SwiftData

struct TeamDetailView: View {
    @Bindable var team: Team
    @Environment(\.theme) private var theme
    @State private var showingEditTeam = false

    @Query private var allGames: [Game]

    private var teamGames: [Game] {
        allGames
            .filter { $0.myTeamID == team.id && $0.isComplete }
            .sorted { $0.date > $1.date }
    }

    private var record: (wins: Int, losses: Int) {
        var w = 0, l = 0
        for game in teamGames {
            if game.myTeamScore > game.opponentScore { w += 1 }
            else if game.opponentScore > game.myTeamScore { l += 1 }
        }
        return (w, l)
    }

    var body: some View {
        List {
            // Team info
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text(team.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        if !teamGames.isEmpty {
                            Text("\(record.wins)-\(record.losses)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }

            // Roster
            Section {
                NavigationLink {
                    RosterView(team: team)
                } label: {
                    HStack {
                        Label("Roster", systemImage: "person.3")
                        Spacer()
                        Text("\(team.activePlayers.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Games
            Section("Games") {
                if teamGames.isEmpty {
                    HStack {
                        Spacer()
                        Label("No games yet", systemImage: "calendar.badge.clock")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                } else {
                    ForEach(teamGames) { game in
                        NavigationLink {
                            GameSummaryView(game: game)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("vs \(game.opponentName)")
                                        .font(.body)
                                    Text(game.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                let won = game.myTeamScore > game.opponentScore
                                Text("\(game.myTeamScore)-\(game.opponentScore)")
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                    .foregroundStyle(won ? theme.winColor : theme.lossColor)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditTeam = true
                }
            }
        }
        .sheet(isPresented: $showingEditTeam) {
            NavigationStack {
                TeamFormView(existingTeam: team)
            }
        }
    }
}
