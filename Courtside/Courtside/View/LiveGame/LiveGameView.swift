import SwiftUI
import SwiftData

struct LiveGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    let game: Game
    @State private var viewModel: LiveGameViewModel?

    var body: some View {
        Group {
            if let viewModel {
                liveGameContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = LiveGameViewModel(game: game, modelContext: modelContext)
                    }
            }
        }
    }

    @ViewBuilder
    private func liveGameContent(viewModel: LiveGameViewModel) -> some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Top bar
                topBar(viewModel: viewModel)

                Divider()

                // Scoreboard + controls
                PeriodControlView(viewModel: viewModel)
                    .padding(.vertical, 8)

                Divider()

                // Main content area
                if viewModel.needsZoneSelection,
                   let stat = viewModel.currentStatType {
                    ShotChartView(
                        validZones: stat.validShotZones,
                        onZoneSelected: { viewModel.selectZone($0) },
                        onCancel: { viewModel.cancelEntry() }
                    )
                } else if viewModel.needsPlayerSelection {
                    ScrollView {
                        PlayerPickerView(
                            players: viewModel.currentPlayers,
                            title: viewModel.isTrackingOpponent ? "Which opponent?" : "Who?",
                            showAddButton: viewModel.isTrackingOpponent,
                            onSelect: { viewModel.selectPlayer($0) },
                            onCancel: { viewModel.cancelEntry() },
                            onAddPlayer: { viewModel.showingAddOpponent = true }
                        )
                    }
                }

                // Stat pad right below scoreboard
                if viewModel.isIdle {
                    StatPadView(viewModel: viewModel)
                        .padding(.top, 8)
                    Spacer(minLength: 0)
                }
            }

            // Undo banner overlay
            UndoBanner(viewModel: viewModel)
                .padding(.bottom, 16)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showingSubstitution },
            set: { viewModel.showingSubstitution = $0 }
        )) {
            SubstitutionSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showingAddOpponent },
            set: { viewModel.showingAddOpponent = $0 }
        )) {
            QuickAddOpponentView(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showingBoxScore },
            set: { viewModel.showingBoxScore = $0 }
        )) {
            NavigationStack {
                BoxScoreView(game: game)
            }
        }
        .alert("End Game?", isPresented: Binding(
            get: { viewModel.showingEndGameConfirm },
            set: { viewModel.showingEndGameConfirm = $0 }
        )) {
            Button("End Game", role: .destructive) {
                viewModel.endGame()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Final score: \(viewModel.myTeamScore) - \(viewModel.opponentScore)")
        }
    }

    @ViewBuilder
    private func topBar(viewModel: LiveGameViewModel) -> some View {
        HStack {
            // Back / end game
            Button {
                viewModel.showingEndGameConfirm = true
            } label: {
                Text("End")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
            }

            Spacer()

            Text("Live Game")
                .font(.headline)

            Spacer()

            // Gym mode toggle
            Button {
                theme.isGymMode.toggle()
                HapticManager.statRecorded()
            } label: {
                Image(systemName: theme.isGymMode ? "sun.max.fill" : "sun.max")
                    .font(.body)
                    .foregroundStyle(theme.isGymMode ? .orange : .secondary)
            }

            // Box score
            Button {
                viewModel.showingBoxScore = true
            } label: {
                Image(systemName: "tablecells")
                    .font(.body)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
