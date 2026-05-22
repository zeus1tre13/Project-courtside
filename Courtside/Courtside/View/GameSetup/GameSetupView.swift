import SwiftUI
import SwiftData

/// New-game setup — a single tight screen. Tracking level is radio cards;
/// the Options block carries the assist-prompt and gym-mode toggles.
struct GameSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

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
    @State private var showingLiveGame = false
    @State private var createdGame: Game?

    @AppStorage("assistPromptDefault") private var promptForAssists = true

    @State private var opponentPlayers: [(number: String, firstName: String, lastName: String)] = []
    @State private var oppNumber = ""
    @State private var oppFirstName = ""
    @State private var oppLastName = ""
    @State private var showingScanRoster = false

    var body: some View {
        VStack(spacing: 0) {
            chrome
            ScrollView {
                VStack(spacing: 0) {
                    yourTeamSection
                    opponentSection
                    formatSection
                    trackingSection
                    if opponentTracking == .individual {
                        opponentRosterSection
                    }
                    colorsSection
                    optionsSection
                }
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            tipOffBar
        }
        .background(CS.bgStage)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingScanRoster) {
            RosterScanView { scanned in
                opponentPlayers.append(contentsOf: scanned)
            }
        }
        .fullScreenCover(isPresented: $showingLiveGame, onDismiss: {
            if createdGame?.isComplete == true { dismiss() }
        }) {
            if let game = createdGame {
                LiveGameView(game: game)
            }
        }
        .onAppear {
            if selectedTeam == nil { selectedTeam = myTeams.first }
        }
    }

    // MARK: - Chrome

    private var chrome: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.csUI(15, weight: .medium))
                .foregroundStyle(CS.inkMute)
            Spacer()
            Text("New game")
                .font(.csUI(16, weight: .bold))
                .foregroundStyle(CS.ink)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "basketball.fill").font(.system(size: 12))
                Text("COURTSIDE").font(.csDisplay(13, weight: .heavy)).tracking(1)
            }
            .foregroundStyle(CS.brand)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .overlay(alignment: .bottom) { Rectangle().fill(CS.line).frame(height: 1) }
    }

    // MARK: - Sections

    private func section<Content: View>(_ label: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.csUI(11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(CS.inkDim)
            content()
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    private var yourTeamSection: some View {
        section("Your team") {
            let team = selectedTeam ?? myTeams.first
            HStack(spacing: 10) {
                Jersey(number: String((team?.displayName ?? "T").prefix(1)),
                       color: CS.home, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(team?.displayName ?? "No team yet")
                        .font(.csDisplay(17, weight: .bold))
                        .foregroundStyle(CS.ink)
                    Text(team.map { "\(playerCount(for: $0)) players" } ?? "Create a team first")
                        .font(.csUI(11))
                        .foregroundStyle(CS.inkMute)
                }
                Spacer()
                if myTeams.count > 1 {
                    Menu {
                        ForEach(myTeams) { t in
                            Button(t.displayName) { selectedTeam = t }
                        }
                    } label: {
                        Text("Change")
                            .font(.csUI(12, weight: .bold))
                            .foregroundStyle(CS.brand)
                    }
                }
            }
            .padding(12)
            .cardStyle()
        }
    }

    private var opponentSection: some View {
        section("Opponent") {
            TextField("Opponent name", text: $opponentName)
                .font(.csUI(16, weight: .semibold))
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(CS.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(CS.lineStrong, lineWidth: 1)
                )
        }
    }

    private var formatSection: some View {
        section("Format") {
            HStack(spacing: 6) {
                ForEach(GameFormat.allCases, id: \.self) { format in
                    Button {
                        gameFormat = format
                    } label: {
                        Text(format.displayName)
                            .font(.csUI(13, weight: .bold))
                            .foregroundStyle(gameFormat == format ? CS.ink : CS.inkMute)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(gameFormat == format ? Color.white : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                            .shadow(color: gameFormat == format ? CS.ink.opacity(0.08) : .clear,
                                    radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(CS.bgSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var trackingSection: some View {
        section("Opponent tracking") {
            VStack(spacing: 6) {
                trackOption(.team, "Team totals only",
                            "Fastest setup. +2 / +3 / +1 quick buttons in the scorer.")
                trackOption(.individual, "Track individual players",
                            "Log per-opponent stats. Requires a roster — scan or add manually.")
                trackOption(.none, "Don't track opponent",
                            "Only log your team.")
            }
        }
    }

    private func trackOption(_ level: OpponentTrackingLevel,
                             _ title: String, _ desc: String) -> some View {
        let selected = opponentTracking == level
        return Button {
            withAnimation(.easeOut(duration: 0.12)) { opponentTracking = level }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? CS.brand : CS.lineStrong, lineWidth: 2)
                        .background(Circle().fill(selected ? CS.brand : .white))
                        .frame(width: 18, height: 18)
                    if selected {
                        Circle().fill(.white).frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.csUI(13, weight: .bold))
                        .foregroundStyle(CS.ink)
                    Text(desc)
                        .font(.csUI(11))
                        .foregroundStyle(CS.inkMute)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(selected ? CS.brand.opacity(0.06) : CS.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? CS.brand : CS.line, lineWidth: 1.4)
            )
        }
        .buttonStyle(.plain)
    }

    private var opponentRosterSection: some View {
        section("Opponent roster") {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextField("#", text: $oppNumber)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 40)
                    TextField("First", text: $oppFirstName)
                        .autocorrectionDisabled()
                    TextField("Last", text: $oppLastName)
                        .autocorrectionDisabled()
                    Button {
                        addOpponentPlayer()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(oppNumber.isEmpty || oppLastName.isEmpty
                                             ? CS.inkDim : CS.made)
                    }
                    .disabled(oppNumber.isEmpty || oppLastName.isEmpty)
                }
                .font(.csUI(14))
                .padding(10)
                .cardStyle()

                ForEach(Array(opponentPlayers.enumerated()), id: \.offset) { index, player in
                    HStack(spacing: 8) {
                        Jersey(number: player.number, color: CS.away, size: 24)
                        Text("\(player.firstName) \(player.lastName)")
                            .font(.csUI(13, weight: .semibold))
                            .foregroundStyle(CS.ink)
                        Spacer()
                        Button {
                            opponentPlayers.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundStyle(CS.inkMute)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .cardStyle()
                }

                Button {
                    showingScanRoster = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.viewfinder")
                        Text("Scan roster from photo")
                    }
                    .font(.csUI(13, weight: .semibold))
                    .foregroundStyle(CS.brand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(CS.brand.opacity(0.4),
                                          style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                    )
                }
            }
        }
    }

    private var colorsSection: some View {
        section("Colors") {
            VStack(spacing: 8) {
                colorRow("Your team", selected: $myTeamColor)
                colorRow(opponentName.isEmpty ? "Opponent" : opponentName,
                         selected: $opponentColor)
            }
        }
    }

    private func colorRow(_ label: String, selected: Binding<TeamColor>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.csUI(11, weight: .semibold))
                .foregroundStyle(CS.inkMute)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(TeamColor.allCases) { tc in
                        Circle()
                            .fill(tc.color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle().strokeBorder(.white,
                                    lineWidth: selected.wrappedValue == tc ? 3 : 0)
                            )
                            .overlay(
                                Circle().strokeBorder(CS.ink.opacity(0.15), lineWidth: 1)
                            )
                            .scaleEffect(selected.wrappedValue == tc ? 1.12 : 1)
                            .onTapGesture {
                                HapticManager.selectionChanged()
                                selected.wrappedValue = tc
                            }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
        .padding(10)
        .cardStyle()
    }

    private var optionsSection: some View {
        section("Options") {
            VStack(spacing: 0) {
                tweakRow("Track shot locations",
                         "Half-court picker after each shot", isOn: $trackShotZones)
                Divider().background(CS.line)
                tweakRow("Prompt for assists",
                         "After a made shot, ask who passed", isOn: $promptForAssists)
                Divider().background(CS.line)
                tweakRow("Gym mode default",
                         "High-contrast for bright gyms",
                         isOn: Binding(get: { theme.isGymMode },
                                       set: { theme.isGymMode = $0 }))
            }
            .padding(.horizontal, 12)
            .cardStyle()
        }
    }

    private func tweakRow(_ title: String, _ desc: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.csUI(13, weight: .bold))
                    .foregroundStyle(CS.ink)
                Text(desc)
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkMute)
            }
        }
        .tint(CS.made)
        .padding(.vertical, 12)
    }

    private var tipOffBar: some View {
        Button {
            startGame()
        } label: {
            Text("TIP OFF →")
                .font(.csDisplay(18, weight: .heavy))
                .tracking(1)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(canStartGame ? CS.brand : CS.lineStrong)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canStartGame)
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(CS.bgStage)
        .overlay(alignment: .top) { Rectangle().fill(CS.line).frame(height: 1) }
    }

    // MARK: - Logic

    private func playerCount(for team: Team) -> Int {
        allPlayers.filter { $0.teamID == team.id && $0.isActive }.count
    }

    private var canStartGame: Bool {
        guard let team = selectedTeam ?? myTeams.first else { return false }
        return !opponentName.trimmingCharacters(in: .whitespaces).isEmpty
            && playerCount(for: team) >= 5
    }

    private func addOpponentPlayer() {
        let num = oppNumber.trimmingCharacters(in: .whitespaces)
        let first = oppFirstName.trimmingCharacters(in: .whitespaces)
        let last = oppLastName.trimmingCharacters(in: .whitespaces)
        guard !num.isEmpty, !last.isEmpty else { return }
        opponentPlayers.append((number: num, firstName: first, lastName: last))
        oppNumber = ""; oppFirstName = ""; oppLastName = ""
    }

    private func startGame() {
        guard let team = selectedTeam ?? myTeams.first else { return }

        let game = Game(
            date: Date(),
            format: gameFormat,
            opponentName: opponentName.trimmingCharacters(in: .whitespaces),
            opponentTrackingLevel: opponentTracking
        )
        game.myTeamID = team.id
        game.trackShotZones = trackShotZones
        game.promptForAssists = promptForAssists
        game.myTeamColorHex = myTeamColor.hex
        game.opponentColorHex = opponentColor.hex

        if opponentTracking == .individual {
            let oppTeam = Team(
                name: opponentName.trimmingCharacters(in: .whitespaces),
                isMyTeam: false
            )
            modelContext.insert(oppTeam)
            game.opponentTeamID = oppTeam.id

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

private extension View {
    func cardStyle() -> some View {
        self
            .background(CS.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CS.line, lineWidth: 1))
    }
}
