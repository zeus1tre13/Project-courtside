import SwiftUI

struct PlayerPickerView: View {
    let players: [Player]
    let title: String
    let onSelect: (Player) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .font(.subheadline)
            }
            .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 10) {
                ForEach(players) { player in
                    Button {
                        onSelect(player)
                    } label: {
                        VStack(spacing: 4) {
                            Text("#\(player.jerseyNumber)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(player.shortName)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
}
