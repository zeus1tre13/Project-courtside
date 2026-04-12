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
                ScrollView {
                    // Player-first mode: show active lineup at top
                    if game.statEntryMode == .playerFirst && viewModel.entryState == .idle {
                        PlayerPickerView(
                            players: viewModel.currentPlayers,
                            title: "Select Player",
                            onSelect: { viewModel.selectPlayer($0) },
                            onCancel: {}
                        )
                    }

                    // Show player picker when needed (stat-first flow)
                    if viewModel.needsPlayerSelection {
                        PlayerPickerView(
                            players: viewModel.currentPlayers,
                            title: "Who?",
                            onSelect: { viewModel.selectPlayer($0) },
                            onCancel: { viewModel.cancelEntry() }
                        )
                    }

                    // Show stat buttons for player-first after player selected
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
                }

                Spacer(minLength: 0)

                // Stat pad (stat-first default, at bottom for thumb reach)
                if game.statEntryMode == .statFirst && !viewModel.needsPlayerSelection {
                    if case .idle = viewModel.entryState {
                        StatPadView(viewModel: viewModel)
                            .padding(.bottom, 8)
                    } else if case .statSelected(let stat, _) = viewModel.entryState,
                              !stat.requiresShotZone {
                        // Waiting for player selection, stat pad hidden
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
