import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme

    @Query(sort: \Team.name)
    private var myTeams: [Team]

    @Query(filter: #Predicate<Game> { $0.isComplete }, sort: \Game.date, order: .reverse)
    private var completedGames: [Game]

    @State private var showingGameSetup = false
    @State private var showingTeamSetupFirst = false
    @State private var showingSettings = false

    private let brandOrange = Color(hex: "#FF5E1A")
    private let headerBackground = Color(hex: "#0a0a0a")

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                // Subtle watermark in the bottom third
                GeometryReader { proxy in
                    Image("courtside-watermark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280)
                        .opacity(0.08)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.75)
                        .allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    header

                    List {
                        // New Game
                        Section {
                            Button {
                                if myTeams.isEmpty {
                                    showingTeamSetupFirst = true
                                } else {
                                    showingGameSetup = true
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(brandOrange)
                                            .frame(width: 28, height: 28)
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    Text("New Game")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(brandOrange)
                                }
                            }
                        }

                        // Teams navigator
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
                                        recentGameRow(game: game)
                                    }
                                    .listRowInsets(EdgeInsets())
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        modelContext.delete(completedGames[index])
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .tint(brandOrange)
            .sheet(isPresented: $showingGameSetup) {
                NavigationStack {
                    GameSetupView()
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Create a Team First",
                   isPresented: $showingTeamSetupFirst) {
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You need to create a team before starting a game.")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack(alignment: .topLeading) {
            headerBackground
                .ignoresSafeArea(edges: .top)

            CourtDiagramView()
                .opacity(0.18)
                .padding(.horizontal, 16)
                .padding(.vertical, 24)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Courtside")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(brandOrange)

                        Text("94 FEET. EVERY INCH, COVERED.")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.54)
                            .foregroundStyle(
                                Color(red: 245/255, green: 245/255, blue: 240/255)
                                    .opacity(0.6)
                            )
                    }

                    Spacer()

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .frame(height: 160)
    }

    // MARK: - Recent Game Row

    private func recentGameRow(game: Game) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(brandOrange)
                .frame(width: 3)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("vs \(game.opponentName)")
                        .font(.body)
                    Text(game.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(game.myTeamScore)-\(game.opponentScore)")
                    .font(.system(size: 17, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(brandOrange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
