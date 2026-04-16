import SwiftUI

/// Sheet shown when the user taps a zone on the shot chart.
/// Lists every field goal attempt from that zone with player, result, and period.
struct ZoneShotListView: View {
    let zone: ShotZone
    let events: [StatEvent]
    let players: [Player]

    @Environment(\.dismiss) private var dismiss

    private var sortedEvents: [StatEvent] {
        events.sorted { $0.sequenceNumber < $1.sequenceNumber }
    }

    private func playerName(for event: StatEvent) -> String {
        guard let pid = event.playerID,
              let player = players.first(where: { $0.id == pid }) else {
            return "Unknown"
        }
        return player.displayLabel
    }

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    ContentUnavailableView(
                        "No shots",
                        systemImage: "circle.slash",
                        description: Text("No field goal attempts recorded for this zone.")
                    )
                } else {
                    List(sortedEvents) { event in
                        HStack(spacing: 12) {
                            // Make/miss indicator
                            Image(systemName: event.statType.isMake ? "circle.fill" : "xmark.circle")
                                .foregroundStyle(event.statType.isMake ? Color.green : Color.red)
                                .font(.system(size: 18))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(playerName(for: event))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(event.statType.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("Q\(event.period)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(zone.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
