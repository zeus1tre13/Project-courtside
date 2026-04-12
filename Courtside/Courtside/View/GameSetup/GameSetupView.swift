import SwiftUI
import SwiftData

struct GameSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Team> { $0.isMyTeam }, sort: \Team.name)
    private var myTeams: [Team]

    @State private var selectedTeam: Team?
    @State private var opponentName: String = ""
    @State private var gameFormat: GameFormat = .fourQuarters
    @State private var opponentTracking: OpponentTrackingLevel = .team
    @State private var statEntryMode: StatEntryMode = .statFirst
    @State private var gameDate: Date = Date()
    @State private var showingLiveGame = false
    @State private var createdGame: Game?

    var body: some View {
        Form {
            Section("Your Team") {
                if myTeams.count == 1 {
                    HStack {
                        Text(myTeams[0].displayName)
                        Spacer()
                        Text("\(myTeams[0].activePlayers.count) players")
                            .foregroundStyle(.secondary)
                    }
                    .onAppear { selectedTeam = myTeams[0] }
                } else {
                    Picker("Select Team", selection: $selectedTeam) {
                        Text("Choose...").tag(nil as Team?)
                        ForEach(myTeams) { team in
                            Text(team.displayName).tag(team as Team?)
                        }
                    }
                }
            }

            Section("Opponent") {
                TextField("Opponent Name", text: $opponentName)
                    .autocorrectionDisabled()
            }

            Section("Game Format") {
                Picker("Format", selection: $gameFormat) {
                    ForEach(GameFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Opponent Tracking") {
                Picker("Track Opponent", selection: $opponentTracking) {
                    ForEach(OpponentTrackingLevel.allCases, id: \.self) { level in
                        VStack(alignment: .leading) {
                            Text(level.displayName)
                        }
                        .tag(level)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()

                Text(opponentTracking.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Stat Entry") {
                Picker("Entry Mode", selection: $statEntryMode) {
                    ForEach(StatEntryMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(statEntryMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    startGame()
                } label: {
                    HStack {
                        Spacer()
                        Text("Start Game")
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(!canStartGame)
            }
        }
        .navigationTitle("New Game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .fullScreenCover(isPresented: $showingLiveGame) {
            if let game = createdGame {
                LiveGameView(game: game)
            }
        }
    }

    private var canStartGame: Bool {
        selectedTeam != nil &&
        !opponentName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (selectedTeam?.activePlayers.count ?? 0) >= 5
    }

    private func startGame() {
        guard let team = selectedTeam else { return }

        let game = Game(
            date: gameDate,
            format: gameFormat,
            opponentName: opponentName.trimmingCharacters(in: .whitespaces),
            opponentTrackingLevel: opponentTracking,
            statEntryMode: statEntryMode
        )
        game.myTeam = team

        if opponentTracking == .individual {
            let oppTeam = Team(
                name: opponentName.trimmingCharacters(in: .whitespaces),
                isMyTeam: false
            )
            modelContext.insert(oppTeam)
            game.opponentTeam = oppTeam
        }

        modelContext.insert(game)
        createdGame = game
        showingLiveGame = true
    }
}
