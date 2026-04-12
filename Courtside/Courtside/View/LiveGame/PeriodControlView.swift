import SwiftUI

struct PeriodControlView: View {
    @Bindable var viewModel: LiveGameViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Scoreboard
            HStack {
                // My team
                VStack(spacing: 2) {
                    Text(viewModel.game.myTeam?.name ?? "Home")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(viewModel.myTeamScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)

                // Period
                VStack(spacing: 4) {
                    Text(viewModel.periodLabel)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Button {
                        viewModel.advancePeriod()
                    } label: {
                        Text("Next")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                // Opponent
                VStack(spacing: 2) {
                    Text(viewModel.game.opponentName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(viewModel.opponentScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)

            // Team toggle + controls
            HStack(spacing: 12) {
                // My Team / Opponent toggle
                if viewModel.game.opponentTrackingLevel != .none {
                    Picker("Team", selection: $viewModel.isTrackingOpponent) {
                        Text("My Team").tag(false)
                        Text("Opponent").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 200)
                }

                Spacer()

                // Sub button
                Button {
                    viewModel.showingSubstitution = true
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.body)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Undo button
                Button {
                    viewModel.undoLastStat()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.body)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.undoStack.isEmpty)
            }
            .padding(.horizontal)
        }
    }
}
