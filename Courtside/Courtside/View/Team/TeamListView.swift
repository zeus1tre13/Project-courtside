import SwiftUI
import SwiftData

/// Teams list — one card per team with color, monogram, record. Empty state
/// for first run.
struct TeamListView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Team.name) private var teams: [Team]
    @Query(filter: #Predicate<Game> { $0.isComplete }) private var completedGames: [Game]

    @State private var showingAddTeam = false

    private var overall: (w: Int, l: Int) {
        teams.reduce(into: (0, 0)) { acc, team in
            let r = record(for: team)
            acc.0 += r.w
            acc.1 += r.l
        }
    }

    var body: some View {
        ZStack {
            CS.bgStage.ignoresSafeArea()
            VStack(spacing: 0) {
                chrome
                if teams.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddTeam) {
            TeamFormView()
        }
    }

    // MARK: - Chrome

    private var chrome: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Home")
                }
                .font(.csUI(15, weight: .semibold))
                .foregroundStyle(CS.brand)
            }
            Spacer()
            Text("Teams")
                .font(.csDisplay(17, weight: .heavy))
                .foregroundStyle(CS.ink)
            Spacer()
            Button { showingAddTeam = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                    Text("Add")
                }
                .font(.csUI(13, weight: .bold))
                .foregroundStyle(CS.brand)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(CS.brandSoft, in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }

    // MARK: - List

    private var list: some View {
        ScrollView {
            VStack(spacing: 8) {
                HStack {
                    ShellSectionLabel(text: "\(teams.count) team\(teams.count == 1 ? "" : "s") · this season")
                    Spacer()
                    Text("\(overall.w)-\(overall.l) overall")
                        .font(.csMono(11))
                        .foregroundStyle(CS.inkMute)
                }
                .padding(.bottom, 2)

                ForEach(teams) { team in
                    NavigationLink { TeamDetailView(team: team) } label: {
                        teamRow(team)
                    }
                    .buttonStyle(PressableButtonStyle())
                }

                Button { showingAddTeam = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add another team")
                    }
                    .font(.csUI(13, weight: .bold))
                    .foregroundStyle(CS.inkMute)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(CS.lineStrong,
                                          style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                    )
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
        .scrollIndicators(.hidden)
    }

    private func teamRow(_ team: Team) -> some View {
        let rec = record(for: team)
        return HStack(spacing: 12) {
            TeamDisc(initials: team.monogram, color: team.accentColor, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(team.schoolName?.isEmpty == false ? team.schoolName! : team.name)
                    .font(.csDisplay(18, weight: .bold))
                    .foregroundStyle(CS.ink)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(team.name)
                    Circle().fill(CS.inkDim).frame(width: 3, height: 3)
                    Text("\(team.activePlayers.count) players").font(.csMono(11))
                }
                .font(.csUI(12))
                .foregroundStyle(CS.inkMute)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(rec.w)-\(rec.l)")
                    .font(.csDisplay(18, weight: .heavy))
                    .foregroundStyle(CS.ink)
                Text("RECORD")
                    .font(.csUI(9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(CS.inkDim)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(CS.inkDim)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
        .overlay(alignment: .leading) {
            Rectangle().fill(team.accentColor).frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .strokeBorder(CS.lineStrong, style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                    .frame(width: 106, height: 106)
                Image(systemName: "person.3")
                    .font(.system(size: 38))
                    .foregroundStyle(CS.inkDim)
                    .frame(width: 90, height: 90)
                    .background(CS.bgSoft, in: Circle())
            }
            .padding(.top, 60)

            Text("No teams yet.")
                .font(.csDisplay(28, weight: .heavy))
                .foregroundStyle(CS.ink)
                .padding(.top, 22)

            Text("Add your first team — school name, jersey color, and roster — to start tracking games.")
                .font(.csUI(14))
                .foregroundStyle(CS.inkMute)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 36)

            Button { showingAddTeam = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("ADD YOUR FIRST TEAM")
                        .font(.csDisplay(16, weight: .heavy))
                        .tracking(0.8)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(height: 52)
                .background(CS.brand)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 22)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func record(for team: Team) -> (w: Int, l: Int) {
        var w = 0, l = 0
        for game in completedGames where game.myTeamID == team.id {
            if game.myTeamScore > game.opponentScore { w += 1 }
            else if game.opponentScore > game.myTeamScore { l += 1 }
        }
        return (w, l)
    }
}
