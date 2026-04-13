import SwiftUI
import SwiftData

struct LiveGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

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
                if game.statEntryMode == .playerFirst {
                    // Player-first flow
                    ScrollView {
                        if viewModel.entryState == .idle {
                            PlayerPickerView(
                                players: viewModel.currentPlayers,
                                title: "Select Player",
                                onSelect: { viewModel.selectPlayer($0) },
                                onCancel: {}
                            )
                        }

                        if case .playerSelected = viewModel.entryState {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("What did they do?")
                                        .font(.headline)
                                    Spacer()
                                    Button("Cancel") { viewModel.cancelEntry() }
                                        .font(.subheadline)
                                }
                                .padding(.horizontal)

                                StatPadView(viewModel: viewModel)
                            }
                        }

                        if case .playerStatSelected = viewModel.entryState {
                            Text("Select zone on court")
                                .font(.headline)
                                .padding()
                        }
                    }
                } else {
                    // Stat-first flow
                    if viewModel.needsZoneSelection,
                       let stat = viewModel.currentStatType {
                        // Shot chart for zone selection
                        ShotChartView(
                            validZones: stat.validShotZones,
                            onZoneSelected: { viewModel.selectZone($0) },
                            onCancel: { viewModel.cancelEntry() }
                        )
                    } else if viewModel.needsPlayerSelection {
                        ScrollView {
                            PlayerPickerView(
                                players: viewModel.currentPlayers,
                                title: "Who?",
                                onSelect: { viewModel.selectPlayer($0) },
                                onCancel: { viewModel.cancelEntry() }
                            )
                        }
                    } else {
                        Spacer()
                    }

                    // Stat pad pinned at bottom
                    if viewModel.isIdle {
                        StatPadView(viewModel: viewModel)
                            .padding(.bottom, 8)
                    }
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
