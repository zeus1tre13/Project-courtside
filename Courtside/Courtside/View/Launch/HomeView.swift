import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Game> { $0.isComplete },
           sort: \Game.date, order: .reverse)
    private var recentGames: [Game]

    @Query(filter: #Predicate<Team> { $0.isMyTeam })
    private var myTeams: [Team]

    @State private var showingGameSetup = false
    @State private var showingTeamSetupFirst = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // New Game button
                    Button {
                        if myTeams.isEmpty {
                            showingTeamSetupFirst = true
                        } else {
                            showingGameSetup = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("New Game")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Teams section
                    NavigationLink {
                        TeamListView()
                    } label: {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .font(.title3)
                            Text("Teams")
                                .font(.title3)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(myTeams.count)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Recent games
                    if !recentGames.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Games")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(recentGames.prefix(5)) { game in
                                NavigationLink {
                                    GameSummaryView(game: game)
                                } label: {
                                    RecentGameRow(game: game)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Courtside")
            .sheet(isPresented: $showingGameSetup) {
                NavigationStack {
                    GameSetupView()
                }
            }
            .alert("Create a Team First",
                   isPresented: $showingTeamSetupFirst) {
                NavigationLink("Create Team") {
                    TeamFormView()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You need to create a team before starting a game.")
            }
        }
    }
}

struct RecentGameRow: View {
    let game: Game

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(game.opponentName)")
                    .font(.body)
                    .fontWeight(.medium)
                Text(game.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Text("\(game.myTeamScore)")
                    .fontWeight(.bold)
                    .foregroundStyle(game.myTeamScore > game.opponentScore ? .green : .primary)
                Text("-")
                    .foregroundStyle(.secondary)
                Text("\(game.opponentScore)")
                    .fontWeight(.bold)
                    .foregroundStyle(game.opponentScore > game.myTeamScore ? .red : .primary)
            }
            .font(.title3)

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
