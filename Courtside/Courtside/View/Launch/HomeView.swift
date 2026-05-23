import SwiftUI
import SwiftData

/// App home — the front door. A dark inked hero makes New Game unmistakable;
/// a teams strip and recent-games list fill the rest. First launch (no teams)
/// shows a welcome state instead.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Team.name) private var myTeams: [Team]
    @Query(filter: #Predicate<Game> { $0.isComplete }, sort: \Game.date, order: .reverse)
    private var completedGames: [Game]

    @State private var showingGameSetup = false
    @State private var showingSettings = false
    @State private var openGame: Game?
    @State private var pendingDeleteGame: Game?

    var body: some View {
        NavigationStack {
            ZStack {
                CS.bgStage.ignoresSafeArea()
                VStack(spacing: 0) {
                    chrome
                    if myTeams.isEmpty {
                        emptyHome
                    } else {
                        defaultHome
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $openGame) { game in
                GameSummaryView(game: game)
            }
            .sheet(isPresented: $showingGameSetup) {
                NavigationStack { GameSetupView() }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert(
                "Delete game?",
                isPresented: Binding(
                    get: { pendingDeleteGame != nil },
                    set: { if !$0 { pendingDeleteGame = nil } }
                ),
                presenting: pendingDeleteGame
            ) { game in
                Button("Delete", role: .destructive) {
                    deleteGame(game)
                    pendingDeleteGame = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDeleteGame = nil
                }
            } message: { game in
                Text("This permanently removes the game vs \(game.opponentName) and all of its stats. This cannot be undone.")
            }
        }
    }

    // MARK: - Delete

    private func deleteGame(_ game: Game) {
        let gameID = game.id
        let predicate = #Predicate<StatEvent> { $0.gameID == gameID }
        let descriptor = FetchDescriptor<StatEvent>(predicate: predicate)
        if let events = try? modelContext.fetch(descriptor) {
            for event in events { modelContext.delete(event) }
        }
        modelContext.delete(game)
        try? modelContext.save()
    }

    // MARK: - Chrome

    private var chrome: some View {
        HStack {
            Color.clear.frame(width: 32, height: 32)
            Spacer()
            Wordmark(size: 14)
            Spacer()
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(CS.inkMute)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }

    // MARK: - Default home

    private var defaultHome: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                teamsStrip
                if !completedGames.isEmpty {
                    recentGames
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(CS.brand)
                    .frame(width: 6, height: 6)
                    .overlay(Circle().stroke(CS.brand.opacity(0.3), lineWidth: 4))
                Text("READY · \(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).uppercased())")
                    .font(.csDisplay(11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(CS.brand)
            }

            Text("Tip off a\nnew game.")
                .font(.csDisplay(40, weight: .black))
                .foregroundStyle(.white)
                .padding(.top, 10)

            Text("94 feet, every inch covered. Pick a team, set the opponent, start tracking.")
                .font(.csUI(13))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 8)

            Button { showingGameSetup = true } label: {
                HStack {
                    Text("NEW GAME")
                        .font(.csDisplay(18, weight: .heavy))
                        .tracking(1)
                    Spacer()
                    HStack(spacing: 8) {
                        Text("TIP OFF")
                            .font(.csMono(11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 58)
                .background(CS.brand)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 16)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CS.ink)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private var teamsStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ShellSectionLabel(text: "Your teams")
                Spacer()
                NavigationLink { TeamListView() } label: {
                    Text("ALL \(myTeams.count) →")
                        .font(.csUI(11, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(CS.brand)
                }
            }
            .padding(.horizontal, 14)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(myTeams) { team in
                        NavigationLink { TeamDetailView(team: team) } label: {
                            teamCard(team)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    NavigationLink { TeamListView() } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(CS.brand)
                            Text("Add")
                                .font(.csUI(11, weight: .bold))
                                .foregroundStyle(CS.inkMute)
                        }
                        .frame(width: 76, height: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(CS.lineStrong,
                                              style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                        )
                    }
                }
                .padding(.horizontal, 14)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.bottom, 14)
    }

    private func teamCard(_ team: Team) -> some View {
        let rec = record(for: team)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                TeamDisc(initials: team.monogram, color: team.accentColor, size: 32)
                Spacer()
                Text("\(rec.w)-\(rec.l)")
                    .font(.csMono(11, weight: .bold))
                    .foregroundStyle(CS.inkMute)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(team.schoolName?.isEmpty == false ? team.schoolName! : team.name)
                    .font(.csDisplay(16, weight: .bold))
                    .foregroundStyle(CS.ink)
                    .lineLimit(1)
                Text("\(team.name) · \(team.activePlayers.count) players")
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkMute)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(width: 158, height: 96, alignment: .topLeading)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
        .overlay(alignment: .leading) {
            Rectangle().fill(team.accentColor).frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var recentGames: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ShellSectionLabel(text: "Recent games")
                Spacer()
                Text("\(completedGames.count) games")
                    .font(.csMono(11))
                    .foregroundStyle(CS.inkMute)
            }
            VStack(spacing: 6) {
                ForEach(completedGames.prefix(8)) { game in
                    SwipeToDeleteRow {
                        GameResultRow(game: game) { openGame = game }
                    } onDelete: {
                        pendingDeleteGame = game
                    }
                }
            }
        }
        .padding(.horizontal, 14)
    }

    // MARK: - Empty home

    private var emptyHome: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image(systemName: "basketball")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(CS.brand)
                    .frame(width: 120, height: 120)
                    .background(CS.brand.opacity(0.06), in: Circle())
                    .overlay(Circle().strokeBorder(CS.brand.opacity(0.3), lineWidth: 1.4))
                    .padding(.top, 32)

                Text("Welcome to Courtside.")
                    .font(.csDisplay(32, weight: .black))
                    .foregroundStyle(CS.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)

                Text("Add your first team to get rolling. You'll be tracking points, fouls and shot zones inside of a minute.")
                    .font(.csUI(14))
                    .foregroundStyle(CS.inkMute)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 24)

                VStack(spacing: 8) {
                    stepRow(1, "Add a team", "School name, jersey color, roster", dim: false)
                    stepRow(2, "Tip off a game", "Pick the opponent, format, options", dim: true)
                    stepRow(3, "Score", "Tap players or stats, in any order", dim: true)
                }
                .padding(.top, 22)
                .padding(.horizontal, 14)

                NavigationLink { TeamListView() } label: {
                    HStack(spacing: 10) {
                        Text("ADD YOUR FIRST TEAM")
                            .font(.csDisplay(17, weight: .heavy))
                            .tracking(1)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(CS.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, 22)
                .padding(.horizontal, 14)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func stepRow(_ n: Int, _ title: String, _ desc: String, dim: Bool) -> some View {
        HStack(spacing: 12) {
            Text("\(n)")
                .font(.csDisplay(14, weight: .heavy))
                .foregroundStyle(dim ? CS.inkDim : CS.brand)
                .frame(width: 28, height: 28)
                .background(dim ? CS.bgSoft : CS.brandSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.csUI(13, weight: .bold))
                    .foregroundStyle(CS.ink)
                Text(desc)
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkMute)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CS.line, lineWidth: 1))
        .opacity(dim ? 0.55 : 1)
    }

    // MARK: - Helpers

    private func record(for team: Team) -> (w: Int, l: Int) {
        var w = 0, l = 0
        for game in completedGames where game.myTeamID == team.id {
            if game.myTeamScore > game.opponentScore { w += 1 }
            else if game.opponentScore > game.myTeamScore { l += 1 }
        }
        return (w, l)
    }
}
