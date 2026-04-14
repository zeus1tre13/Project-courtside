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
    @State private var trackShotZones: Bool = true
    @State private var myTeamColor: TeamColor = .blue
    @State private var opponentColor: TeamColor = .red
    @State private var gameDate: Date = Date()
    @State private var showingLiveGame = false
    @State private var createdGame: Game?

    // Opponent roster (inline quick-add)
    @State private var opponentPlayers: [(number: String, firstName: String, lastName: String)] = []
    @State private var oppNumber: String = ""
    @State private var oppFirstName: String = ""
    @State private var oppLastName: String = ""
    @State private var showingScanRoster = false

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

            // Opponent roster — only when tracking individual players
            if opponentTracking == .individual {
                Section("Opponent Roster") {
                    // Quick-add row
                    HStack(spacing: 8) {
                        TextField("#", text: $oppNumber)
                            .keyboardType(.numberPad)
                            .frame(width: 44)
                        TextField("First", text: $oppFirstName)
                            .autocorrectionDisabled()
                        TextField("Last", text: $oppLastName)
                            .autocorrectionDisabled()
                        Button {
                            addOpponentPlayer()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                        }
                        .disabled(oppNumber.isEmpty || oppLastName.isEmpty)
                    }

                    // Added players
                    ForEach(Array(opponentPlayers.enumerated()), id: \.offset) { index, player in
                        HStack {
                            Text("#\(player.number)")
                                .fontWeight(.bold)
                                .frame(width: 44)
                            Text("\(player.firstName) \(player.lastName)")
                            Spacer()
                        }
                    }
                    .onDelete { offsets in
                        opponentPlayers.remove(atOffsets: offsets)
                    }

                    // Scan button
                    Button {
                        showingScanRoster = true
                    } label: {
                        Label("Scan Roster from Photo", systemImage: "camera.viewfinder")
                    }

                    if opponentPlayers.isEmpty {
                        Text("Add opponent players or scan a roster photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(opponentPlayers.count) players added")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Team Colors") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Team")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ColorPaletteRow(selected: $myTeamColor)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Opponent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ColorPaletteRow(selected: $opponentColor)
                }
            }

            Section("Shot Chart") {
                Toggle("Track Shot Locations", isOn: $trackShotZones)

                Text("Show a half-court after each shot to record where it was taken")
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
        .sheet(isPresented: $showingScanRoster) {
            RosterScanView { scannedPlayers in
                for player in scannedPlayers {
                    opponentPlayers.append(player)
                }
            }
        }
        .fullScreenCover(isPresented: $showingLiveGame, onDismiss: {
            // If the game was ended, dismiss setup back to HomeView
            if createdGame?.isComplete == true {
                dismiss()
            }
        }) {
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

    private func addOpponentPlayer() {
        let num = oppNumber.trimmingCharacters(in: .whitespaces)
        let first = oppFirstName.trimmingCharacters(in: .whitespaces)
        let last = oppLastName.trimmingCharacters(in: .whitespaces)
        guard !num.isEmpty, !last.isEmpty else { return }
        opponentPlayers.append((number: num, firstName: first, lastName: last))
        oppNumber = ""
        oppFirstName = ""
        oppLastName = ""
    }

    private func startGame() {
        guard let team = selectedTeam else { return }

        let game = Game(
            date: gameDate,
            format: gameFormat,
            opponentName: opponentName.trimmingCharacters(in: .whitespaces),
            opponentTrackingLevel: opponentTracking
        )
        game.myTeamID = team.id
        game.trackShotZones = trackShotZones
        game.myTeamColorHex = myTeamColor.hex
        game.opponentColorHex = opponentColor.hex

        if opponentTracking == .individual {
            let oppTeam = Team(
                name: opponentName.trimmingCharacters(in: .whitespaces),
                isMyTeam: false
            )
            modelContext.insert(oppTeam)
            game.opponentTeamID = oppTeam.id

            // Create opponent players
            for opp in opponentPlayers {
                let player = Player(
                    firstName: opp.firstName,
                    lastName: opp.lastName,
                    jerseyNumber: opp.number
                )
                player.teamID = oppTeam.id
                modelContext.insert(player)
            }
        }

        modelContext.insert(game)
        createdGame = game
        showingLiveGame = true
    }
}

struct ColorPaletteRow: View {
    @Binding var selected: TeamColor

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(TeamColor.allCases) { tc in
                Circle()
                    .fill(tc.color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(.white, lineWidth: selected == tc ? 3 : 0)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(tc.color.opacity(0.8), lineWidth: selected == tc ? 2 : 0)
                            .padding(2)
                    )
                    .shadow(color: selected == tc ? tc.color.opacity(0.5) : .clear, radius: 6)
                    .scaleEffect(selected == tc ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: selected)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticManager.selectionChanged()
                        selected = tc
                    }
            }
        }
    }
}
