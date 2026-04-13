import SwiftUI
import SwiftData

struct GameSummaryView: View {
    let game: Game
    @Query private var allTeams: [Team]

    private var myTeamName: String {
        guard let teamID = game.myTeamID else { return "My Team" }
        return allTeams.first { $0.id == teamID }?.displayName ?? "My Team"
    }

    private var myColor: Color { Color(hex: game.myTeamColorHex) }
    private var oppColor: Color { Color(hex: game.opponentColorHex) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Score header
                HStack {
                    VStack {
                        Text(myTeamName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text("\(game.myTeamScore)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(myColor)
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
                            .lineLimit(1)
                        Text("\(game.opponentScore)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(oppColor)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()

                // Period scores
                if game.isComplete {
                    PeriodScoresView(game: game, myTeamName: myTeamName, myColor: myColor, oppColor: oppColor)
                        .padding(.horizontal)
                }

                // Box score
                VStack(alignment: .leading, spacing: 8) {
                    Text("Box Score")
                        .font(.headline)
                        .padding(.horizontal)

                    BoxScoreView(game: game)
                }
            }
        }
        .navigationTitle("Game Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PeriodScoresView: View {
    let game: Game
    var myTeamName: String = "My Team"
    var myColor: Color = .blue
    var oppColor: Color = .red

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
                Text(myTeamName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(myColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Array(periods), id: \.self) { period in
                    Text("\(game.scoreForPeriod(period, isOpponent: false))")
                        .frame(width: 40)
                }
                Text("\(game.myTeamScore)")
                    .fontWeight(.bold)
                    .foregroundStyle(myColor)
                    .frame(width: 40)
            }
            .font(.subheadline)
            .padding(.vertical, 6)

            Divider()

            // Opponent row
            HStack {
                Text(game.opponentName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(oppColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Array(periods), id: \.self) { period in
                    Text("\(game.scoreForPeriod(period, isOpponent: true))")
                        .frame(width: 40)
                }
                Text("\(game.opponentScore)")
                    .fontWeight(.bold)
                    .foregroundStyle(oppColor)
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
