import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Team.name)
    private var myTeams: [Team]

    @Query(filter: #Predicate<Game> { $0.isComplete }, sort: \Game.date, order: .reverse)
    private var completedGames: [Game]

    @State private var showingGameSetup = false
    @State private var showingTeamSetupFirst = false

    var body: some View {
        NavigationStack {
            List {
                // New Game button
                Section {
                    Button {
                        if myTeams.isEmpty {
                            showingTeamSetupFirst = true
                        } else {
                            showingGameSetup = true
                        }
                    } label: {
                        Label("New Game", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                }

                // Teams section
                Section {
                    NavigationLink {
                        TeamListView()
                    } label: {
                        HStack {
                            Label("Teams", systemImage: "person.3.fill")
                            Spacer()
                            Text("\(myTeams.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Recent Games
                if !completedGames.isEmpty {
                    Section("Recent Games") {
                        ForEach(completedGames) { game in
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
                                        .font(.headline)
                                        .foregroundStyle(won ? .green : .red)
                                }
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(completedGames[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Courtside")
            .sheet(isPresented: $showingGameSetup) {
                NavigationStack {
                    GameSetupView()
                }
            }
            .alert("Create a Team First",
                   isPresented: $showingTeamSetupFirst) {
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You need to create a team before starting a game.")
            }
        }
    }
}
