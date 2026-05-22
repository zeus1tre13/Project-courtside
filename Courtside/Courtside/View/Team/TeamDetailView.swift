import SwiftUI
import SwiftData

/// Team detail — a color-tinted hero treating each team as its own little
/// brand, two nav cards (Roster, Analytics), and the games list.
struct TeamDetailView: View {
    @Bindable var team: Team
    @Environment(\.dismiss) private var dismiss

    @Query private var allGames: [Game]
    @Query private var allPlayers: [Player]

    @State private var showingEditTeam = false
    @State private var openGame: Game?

    private var teamGames: [Game] {
        allGames
            .filter { $0.myTeamID == team.id && $0.isComplete }
            .sorted { $0.date > $1.date }
    }

    private var teamPlayers: [Player] {
        allPlayers.filter { $0.teamID == team.id }
    }

    private var record: (w: Int, l: Int) {
        var w = 0, l = 0
        for game in teamGames {
            if game.myTeamScore > game.opponentScore { w += 1 }
            else if game.opponentScore > game.myTeamScore { l += 1 }
        }
        return (w, l)
    }

    var body: some View {
        ZStack {
            CS.bgStage.ignoresSafeArea()
            VStack(spacing: 0) {
                chrome
                ScrollView {
                    VStack(spacing: 0) {
                        hero
                        navCards
                        gamesSection
                    }
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $openGame) { game in
            GameSummaryView(game: game)
        }
        .sheet(isPresented: $showingEditTeam) {
            TeamFormView(existingTeam: team)
        }
    }

    // MARK: - Chrome

    private var chrome: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Teams")
                }
                .font(.csUI(15, weight: .semibold))
                .foregroundStyle(CS.brand)
            }
            Spacer()
            Wordmark(size: 12)
            Spacer()
            Button { showingEditTeam = true } label: {
                Text("Edit")
                    .font(.csUI(14, weight: .bold))
                    .foregroundStyle(CS.brand)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }

    // MARK: - Hero

    private var hero: some View {
        let winPct = record.w + record.l > 0
            ? Int(Double(record.w) / Double(record.w + record.l) * 100)
            : 0
        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                TeamDisc(initials: team.monogram, color: team.accentColor, size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(team.name.uppercased())
                        .font(.csUI(11, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(CS.inkMute)
                        .lineLimit(1)
                    Text(team.schoolName?.isEmpty == false ? team.schoolName! : team.name)
                        .font(.csDisplay(28, weight: .heavy))
                        .foregroundStyle(CS.ink)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                heroStat("Record", "\(record.w)-\(record.l)", accent: team.accentColor)
                heroStat("Players", "\(teamPlayers.count)", accent: CS.ink)
                heroStat("Win %", "\(winPct)%", accent: CS.ink)
            }
        }
        .padding(18)
        .background(team.accentColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(team.accentColor.opacity(0.35), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            TeamDisc(initials: team.monogram, color: team.accentColor, size: 150)
                .opacity(0.06)
                .offset(x: 40, y: -20)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func heroStat(_ label: String, _ value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.csDisplay(24, weight: .heavy))
                .foregroundStyle(accent)
            Text(label.uppercased())
                .font(.csUI(9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(CS.inkDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CS.line, lineWidth: 1))
    }

    // MARK: - Nav cards

    private var navCards: some View {
        HStack(spacing: 8) {
            NavCardLink(
                systemImage: "person.2.fill",
                label: "Roster",
                sub: "\(team.activePlayers.count) active",
                destination: RosterView(team: team)
            )
            NavCardLink(
                systemImage: "chart.bar.fill",
                label: "Analytics",
                sub: "Hot zones · leaders",
                destination: TeamAnalyticsView(team: team)
            )
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    // MARK: - Games

    private var gamesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ShellSectionLabel(text: "Games")
                Spacer()
                if !teamGames.isEmpty {
                    Text("\(teamGames.count) · this season")
                        .font(.csMono(11))
                        .foregroundStyle(CS.inkMute)
                }
            }
            if teamGames.isEmpty {
                VStack(spacing: 6) {
                    Text("No games yet.")
                        .font(.csDisplay(17, weight: .bold))
                        .foregroundStyle(CS.ink)
                    Text("Start a new game with this team and it'll show up here as soon as you tip off.")
                        .font(.csUI(12))
                        .foregroundStyle(CS.inkMute)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(22)
                .background(CS.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(CS.lineStrong,
                                      style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                )
            } else {
                VStack(spacing: 6) {
                    ForEach(teamGames) { game in
                        GameResultRow(game: game) { openGame = game }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
    }
}

/// A NavCard that pushes a destination via NavigationLink.
private struct NavCardLink<Destination: View>: View {
    let systemImage: String
    let label: String
    let sub: String
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(CS.brand)
                    .frame(width: 36, height: 36)
                    .background(CS.brandSoft, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.csDisplay(17, weight: .heavy))
                        .foregroundStyle(CS.ink)
                    Text(sub)
                        .font(.csUI(11))
                        .foregroundStyle(CS.inkMute)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(CS.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CS.inkDim)
                    .padding(14)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}
