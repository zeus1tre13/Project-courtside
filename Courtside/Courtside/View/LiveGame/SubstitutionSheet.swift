import SwiftUI

/// Two-column substitution sheet — pick one player to take out and one to
/// put in, see the swap preview, then commit with a single Confirm.
struct SubstitutionSheet: View {
    @Bindable var viewModel: LiveGameViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedOut: Player?
    @State private var selectedIn: Player?

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(CS.lineStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 12)

            HStack {
                Text("Substitute")
                    .font(.csDisplay(22, weight: .bold))
                    .foregroundStyle(CS.ink)
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(.csUI(13, weight: .semibold))
                    .foregroundStyle(CS.inkMute)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)

            ScrollView {
                HStack(alignment: .top, spacing: 10) {
                    column(title: "Take out", players: viewModel.activeLineup,
                           selection: $selectedOut, color: CS.home, dim: false)
                    column(title: "Put in", players: viewModel.benchPlayers,
                           selection: $selectedIn, color: CS.inkMute, dim: true)
                }
                .padding(.horizontal, 14)
            }
            .scrollIndicators(.hidden)

            if viewModel.benchPlayers.isEmpty {
                Text("No bench players available to sub in.")
                    .font(.csUI(12))
                    .foregroundStyle(CS.inkMute)
                    .padding(.vertical, 10)
            }

            swapPreview

            Button {
                if let out = selectedOut, let inP = selectedIn {
                    viewModel.substitute(playerOut: out, playerIn: inP)
                    dismiss()
                }
            } label: {
                Text("Confirm sub")
                    .font(.csUI(15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(canConfirm ? CS.brand : CS.lineStrong)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canConfirm)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .background(CS.bgStage)
    }

    private var canConfirm: Bool { selectedOut != nil && selectedIn != nil }

    // MARK: - Column

    private func column(title: String, players: [Player],
                        selection: Binding<Player?>, color: Color, dim: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.csUI(10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(CS.inkDim)
            ForEach(players, id: \.id) { player in
                let isSelected = selection.wrappedValue?.id == player.id
                Button {
                    selection.wrappedValue = isSelected ? nil : player
                    HapticManager.selectionChanged()
                } label: {
                    HStack(spacing: 8) {
                        Jersey(number: player.jerseyNumber, color: color, size: 28, dim: dim)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(player.lastName.isEmpty ? player.fullName : player.lastName)
                                .font(.csUI(13, weight: .bold))
                                .foregroundStyle(CS.ink)
                                .lineLimit(1)
                            Text("#\(player.jerseyNumber)")
                                .font(.csMono(10))
                                .foregroundStyle(CS.inkMute)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(isSelected ? CS.home.opacity(0.12) : CS.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? CS.home : CS.line, lineWidth: 1.4)
                    )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Swap preview

    @ViewBuilder
    private var swapPreview: some View {
        if let out = selectedOut, let inP = selectedIn {
            HStack(spacing: 8) {
                Jersey(number: out.jerseyNumber, color: CS.home, size: 28)
                Text(out.lastName.isEmpty ? out.fullName : out.lastName)
                    .font(.csUI(13, weight: .bold))
                Spacer()
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CS.inkMute)
                Spacer()
                Text(inP.lastName.isEmpty ? inP.fullName : inP.lastName)
                    .font(.csUI(13, weight: .bold))
                Jersey(number: inP.jerseyNumber, color: CS.inkMute, size: 28, dim: true)
            }
            .foregroundStyle(CS.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(CS.home.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12).strokeBorder(CS.home, lineWidth: 1)
            )
            .padding(.horizontal, 14)
            .padding(.top, 10)
        }
    }
}
