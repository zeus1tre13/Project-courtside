import SwiftUI

struct PeriodControlView: View {
    @Bindable var viewModel: LiveGameViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Scoreboard
            HStack {
                // My team
                VStack(spacing: 2) {
                    Text(viewModel.myTeamName)
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
                    TeamToggle(
                        myTeamName: viewModel.myTeamName,
                        opponentName: viewModel.game.opponentName,
                        myColor: viewModel.myTeamColor,
                        oppColor: viewModel.opponentColor,
                        isOpponent: $viewModel.isTrackingOpponent
                    )
                    .frame(maxWidth: 220)
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

struct TeamToggle: View {
    let myTeamName: String
    let opponentName: String
    var myColor: Color = .blue
    var oppColor: Color = .red
    @Binding var isOpponent: Bool

    var body: some View {
        HStack(spacing: 0) {
            toggleButton(label: myTeamName, isSelected: !isOpponent, color: myColor) {
                withAnimation(.easeInOut(duration: 0.2)) { isOpponent = false }
            }
            toggleButton(label: opponentName, isSelected: isOpponent, color: oppColor) {
                withAnimation(.easeInOut(duration: 0.2)) { isOpponent = true }
            }
        }
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func toggleButton(label: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .medium)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(isSelected ? color.opacity(0.2) : Color.clear)
                .foregroundStyle(isSelected ? color : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }
}
