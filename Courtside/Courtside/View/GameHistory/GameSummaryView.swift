import SwiftUI
import SwiftData

struct GameSummaryView: View {
    let game: Game

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Score header
                HStack {
                    VStack {
                        Text(game.myTeam?.displayName ?? "My Team")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(game.myTeamScore)")
                            .font(.system(size: 48, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        Text("vs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(game.date, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack {
                        Text(game.opponentName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(game.opponentScore)")
                            .font(.system(size: 48, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()

                // Period scores
                if game.isComplete {
                    PeriodScoresView(game: game)
                        .padding(.horizontal)
                }

                // Box score placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Text("Box Score")
                        .font(.headline)
                        .padding(.horizontal)

                    Text("Full box score view coming in Phase 1D")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Game Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PeriodScoresView: View {
    let game: Game

    var body: some View {
        let periods = 1...game.currentPeriod

        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Team")
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Array(periods), id: \.self) { period in
                    Text(game.format.periodLabel(for: period))
                        .frame(width: 40)
                }
                Text("T")
                    .fontWeight(.bold)
                    .frame(width: 40)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)

            Divider()

            // My team row
            HStack {
                Text(game.myTeam?.name ?? "My Team")
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Array(periods), id: \.self) { period in
                    Text("\(game.scoreForPeriod(period, isOpponent: false))")
                        .frame(width: 40)
                }
                Text("\(game.myTeamScore)")
                    .fontWeight(.bold)
                    .frame(width: 40)
            }
            .font(.subheadline)
            .padding(.vertical, 6)

            Divider()

            // Opponent row
            HStack {
                Text(game.opponentName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Array(periods), id: \.self) { period in
                    Text("\(game.scoreForPeriod(period, isOpponent: true))")
                        .frame(width: 40)
                }
                Text("\(game.opponentScore)")
                    .fontWeight(.bold)
                    .frame(width: 40)
            }
            .font(.subheadline)
            .padding(.vertical, 6)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
