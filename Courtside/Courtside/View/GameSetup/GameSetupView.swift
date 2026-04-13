import SwiftUI
import SwiftData

struct GameSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Team> { $0.isMyTeam }, sort: \Team.name)
    private var myTeams: [Team]

    @Query private var allPlayers: [Player]

    @State private var selectedTeam: Team?
    @State private var opponentName: String = ""
    @State private var gameFormat: GameFormat = .fourQuarters
    @State private var opponentTracking: OpponentTrackingLevel = .team
    @State private var statEntryMode: StatEntryMode = .statFirst
    @State private var trackShotZones: Bool = true
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
                        Text("\(playerCount(for: myTeams[0])) players")
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

            Section("Shot Chart") {
                Toggle("Track Shot Locations", isOn: $trackShotZones)

                Text("Show a half-court after each shot to record where it was taken")
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

    private func playerCount(for team: Team) -> Int {
        allPlayers.filter { $0.teamID == team.id && $0.isActive }.count
    }

    private var canStartGame: Bool {
        guard let team = selectedTeam else { return false }
        return !opponentName.trimmingCharacters(in: .whitespaces).isEmpty &&
               playerCount(for: team) >= 5
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
        game.myTeamID = team.id
        game.trackShotZones = trackShotZones

        if opponentTracking == .individual {
            let oppTeam = Team(
                name: opponentName.trimmingCharacters(in: .whitespaces),
                isMyTeam: false
            )
            modelContext.insert(oppTeam)
            game.opponentTeamID = oppTeam.id
        }

        modelContext.insert(game)
        createdGame = game
        showingLiveGame = true
    }
}
