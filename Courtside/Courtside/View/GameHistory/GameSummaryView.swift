import SwiftUI
import SwiftData

/// Post-game container — a shared score header and sub-nav over the three
/// connected views: Recap, Box score, and Shot chart (plus a Play-by-play
/// stub). Replaces the old single-scroll game summary.
struct GameSummaryView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    @Query private var allTeams: [Team]
    @Query private var allPlayers: [Player]
    @Query private var allEvents: [StatEvent]

    @State private var tab: PostGameTab = .recap
    @State private var shareURL: URL?
    @State private var showingShare = false

    enum PostGameTab: String, CaseIterable {
        case recap, box, shots, plays
        var label: String {
            switch self {
            case .recap: return "Recap"
            case .box:   return "Box score"
            case .shots: return "Shot chart"
            case .plays: return "Play-by-play"
            }
        }
    }

    // MARK: - Data

    private var gameEvents: [StatEvent] {
        allEvents.filter { $0.gameID == game.id && !$0.isDeleted }
    }

    private var myPlayers: [Player] {
        guard let teamID = game.myTeamID else { return [] }
        return allPlayers
            .filter { $0.teamID == teamID }
            .sorted { (Int($0.jerseyNumber) ?? 999) < (Int($1.jerseyNumber) ?? 999) }
    }

    private var opponentPlayers: [Player] {
        guard let teamID = game.opponentTeamID else { return [] }
        return allPlayers.filter { $0.teamID == teamID }
    }

    private var myTeamName: String {
        guard let teamID = game.myTeamID else { return "My Team" }
        return allTeams.first { $0.id == teamID }?.displayName ?? "My Team"
    }

    private var myScore: Int {
        StatCalculator.teamBoxScoreLine(from: gameEvents, isOpponent: false).points
    }
    private var oppScore: Int {
        StatCalculator.teamBoxScoreLine(from: gameEvents, isOpponent: true).points
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            chrome
            scoreHeader
            subNav
            tabContent
        }
        .background(CS.bgStage)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingShare) {
            if let shareURL {
                ShareSheet(items: [shareURL])
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Chrome

    private var chrome: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Games")
                }
                .font(.csUI(15, weight: .semibold))
                .foregroundStyle(CS.brand)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "basketball.fill")
                    .font(.system(size: 14))
                Text("COURTSIDE")
                    .font(.csDisplay(15, weight: .heavy))
                    .tracking(1)
            }
            .foregroundStyle(CS.brand)
            Spacer()
            Button { exportCSV() } label: {
                Text("Export")
                    .font(.csUI(14, weight: .semibold))
                    .foregroundStyle(CS.brand)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }

    // MARK: - Score header

    private var margin: Int { abs(myScore - oppScore) }

    private var resultPill: (text: String, color: Color) {
        if myScore > oppScore { return ("W +\(margin)", CS.made) }
        if myScore < oppScore { return ("L \(margin)", CS.danger) }
        return ("TIE", CS.inkMute)
    }

    private var scoreHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("FINAL · \(game.date.formatted(.dateTime.month(.abbreviated).day().year()))")
                    .font(.csUI(10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(CS.inkDim)
                Spacer()
                Text(resultPill.text)
                    .font(.csUI(10, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(resultPill.color, in: Capsule())
            }

            HStack(spacing: 10) {
                teamScore(name: myTeamName, score: myScore, color: CS.home,
                          winner: myScore >= oppScore, reversed: false)
                Text("·")
                    .font(.csDisplay(22, weight: .bold))
                    .foregroundStyle(CS.inkDim)
                teamScore(name: game.opponentName, score: oppScore, color: CS.away,
                          winner: oppScore > myScore, reversed: true)
            }
        }
        .padding(16)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(CS.line, lineWidth: 1))
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    private func teamScore(name: String, score: Int, color: Color,
                           winner: Bool, reversed: Bool) -> some View {
        let label = VStack(alignment: reversed ? .trailing : .leading, spacing: 0) {
            Text((name.isEmpty ? (reversed ? "Opponent" : "Team") : name).uppercased())
                .font(.csUI(11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(CS.inkMute)
                .lineLimit(1)
            Text("\(score)")
                .font(.csDisplay(52, weight: .heavy))
                .foregroundStyle(winner ? CS.ink : CS.inkMute)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        let jersey = Jersey(number: String(name.prefix(1)).uppercased(),
                            color: color, size: 36)
        return HStack(spacing: 10) {
            if reversed { label; jersey } else { jersey; label }
        }
        .frame(maxWidth: .infinity, alignment: reversed ? .trailing : .leading)
    }

    // MARK: - Sub-nav

    private var subNav: some View {
        HStack(spacing: 4) {
            ForEach(PostGameTab.allCases, id: \.self) { item in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { tab = item }
                } label: {
                    Text(item.label)
                        .font(.csUI(13, weight: .bold))
                        .foregroundStyle(tab == item ? CS.ink : CS.inkMute)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(tab == item ? CS.brand : .clear)
                                .frame(height: 2)
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CS.line).frame(height: 1)
        }
    }

    // MARK: - Tab content

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .recap:
            ScrollView {
                PostGameRecapView(
                    game: game,
                    events: gameEvents,
                    myPlayers: myPlayers,
                    myTeamName: myTeamName,
                    onOpenShotChart: { withAnimation { tab = .shots } }
                )
            }
            .scrollIndicators(.hidden)
        case .box:
            BoxScoreView(game: game)
        case .shots:
            ShotHeatMapView(events: gameEvents, myPlayers: myPlayers)
        case .plays:
            PlayByPlayView(
                game: game,
                events: gameEvents,
                players: myPlayers + opponentPlayers,
                myTeamName: myTeamName
            )
        }
    }

    // MARK: - Export

    private func exportCSV() {
        let oppPlayers: [Player] = {
            guard let teamID = game.opponentTeamID else { return [] }
            return allPlayers.filter { $0.teamID == teamID }
        }()
        let csv = CSVExporter.exportBoxScore(
            game: game,
            myTeamName: myTeamName,
            players: myPlayers,
            opponentPlayers: oppPlayers,
            events: gameEvents
        )
        if let url = CSVExporter.writeToFile(
            csv: csv,
            myTeamName: myTeamName,
            opponentName: game.opponentName,
            date: game.date
        ) {
            shareURL = url
            showingShare = true
        }
    }
}
