import SwiftUI

struct SubstitutionSheet: View {
    @Bindable var viewModel: LiveGameViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedOut: Player?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Step 1: Select player to sub out
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedOut == nil ? "Tap player to sub OUT" : "Tap player to sub IN")
                        .font(.headline)
                        .padding(.horizontal)

                    if selectedOut == nil {
                        // Show active lineup
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 10) {
                            ForEach(viewModel.activeLineup) { player in
                                Button {
                                    selectedOut = player
                                    HapticManager.selectionChanged()
                                } label: {
                                    PlayerCard(player: player, isSelected: false, color: .red.opacity(0.15))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Show who's coming out
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(.red)
                            Text("\(selectedOut!.displayLabel) coming out")
                                .font(.subheadline)
                            Spacer()
                            Button("Change") {
                                selectedOut = nil
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)

                        // Show bench players
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 10) {
                            ForEach(viewModel.benchPlayers) { player in
                                Button {
                                    viewModel.substitute(playerOut: selectedOut!, playerIn: player)
                                    dismiss()
                                } label: {
                                    PlayerCard(player: player, isSelected: false, color: .green.opacity(0.15))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Substitution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct PlayerCard: View {
    let player: Player
    let isSelected: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("#\(player.jerseyNumber)")
                .font(.title3)
                .fontWeight(.bold)
            Text(player.shortName)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}
