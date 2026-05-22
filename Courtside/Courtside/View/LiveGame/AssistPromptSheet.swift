import SwiftUI

/// Appears after a made 2PT/3PT — credit the assist or dismiss as unassisted.
/// Auto-skips after 5 seconds so a fast-play scorer is never blocked.
struct AssistPromptSheet: View {
    let viewModel: LiveGameViewModel

    @State private var remaining = 5

    private var scorer: Player? { viewModel.assistPromptScorer }

    private var shotLabel: String {
        guard let event = viewModel.lastUndoableEvent else { return "Made basket" }
        let made = event.statType == .threePointMade ? "3PT" : "2PT"
        return "\(made) made +\(event.statType.pointValue)"
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(CS.lineStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 12)

            header
                .padding(.horizontal, 14)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(viewModel.assistCandidates, id: \.id) { teammate in
                    Button {
                        viewModel.recordAssist(by: teammate)
                    } label: {
                        HStack(spacing: 10) {
                            Jersey(number: teammate.jerseyNumber, color: CS.home, size: 32)
                            Text(teammate.lastName.isEmpty ? teammate.fullName : teammate.lastName)
                                .font(.csUI(13, weight: .bold))
                                .foregroundStyle(CS.ink)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(CS.bgStage)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(CS.line, lineWidth: 1.4)
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            Button {
                viewModel.dismissAssistPrompt()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CS.inkMute)
                    Text("No assist · unassisted")
                }
                .font(.csUI(14, weight: .bold))
                .foregroundStyle(CS.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(CS.bgSoft, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            Text("Auto-dismisses in \(remaining)s · toggle this off in Settings.")
                .font(.csUI(11))
                .foregroundStyle(CS.inkDim)
                .padding(.top, 8)
                .padding(.bottom, 16)
        }
        .background(CS.bgStage)
        .task {
            for value in stride(from: 5, through: 1, by: -1) {
                remaining = value
                do { try await Task.sleep(for: .seconds(1)) }
                catch { return }
            }
            viewModel.dismissAssistPrompt()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(CS.made)
                .frame(width: 32, height: 32)
                .background(CS.madeSoft, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text("\(shotLabel.uppercased()) · #\(scorer?.jerseyNumber ?? "") \((scorer?.lastName ?? "").uppercased())")
                    .font(.csUI(11, weight: .heavy))
                    .tracking(0.6)
                    .foregroundStyle(CS.made)
                    .lineLimit(1)
                Text("Who passed it?")
                    .font(.csDisplay(18, weight: .bold))
                    .foregroundStyle(CS.ink)
            }
            Spacer(minLength: 0)
            Text("auto-skip \(remaining)s")
                .font(.csMono(10))
                .foregroundStyle(CS.inkDim)
        }
    }
}
