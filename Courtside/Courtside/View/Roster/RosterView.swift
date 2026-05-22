import SwiftUI
import SwiftData

/// Roster — Active and Inactive sections of jersey-disc player rows. The "+"
/// opens a menu for manual add or roster scan.
struct RosterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var team: Team
    @Query private var allPlayers: [Player]

    @State private var showingAddPlayer = false
    @State private var showingScanRoster = false
    @State private var editPlayer: Player?

    private var teamPlayers: [Player] {
        allPlayers
            .filter { $0.teamID == team.id }
            .sorted { (Int($0.jerseyNumber) ?? 999) < (Int($1.jerseyNumber) ?? 999) }
    }
    private var activePlayers: [Player] { teamPlayers.filter { $0.isActive } }
    private var inactivePlayers: [Player] { teamPlayers.filter { !$0.isActive } }

    var body: some View {
        ZStack {
            CS.bgStage.ignoresSafeArea()
            VStack(spacing: 0) {
                chrome
                if teamPlayers.isEmpty {
                    emptyState
                } else {
                    roster
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddPlayer) {
            PlayerFormView(team: team)
        }
        .sheet(item: $editPlayer) { player in
            PlayerFormView(team: team, existingPlayer: player)
        }
        .sheet(isPresented: $showingScanRoster) {
            RosterScanView { scanned in
                for p in scanned {
                    let player = Player(
                        firstName: p.firstName,
                        lastName: p.lastName,
                        jerseyNumber: p.number
                    )
                    player.teamID = team.id
                    modelContext.insert(player)
                }
            }
        }
    }

    // MARK: - Chrome

    private var chrome: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Team")
                }
                .font(.csUI(15, weight: .semibold))
                .foregroundStyle(CS.brand)
            }
            Spacer()
            Text("Roster")
                .font(.csDisplay(17, weight: .heavy))
                .foregroundStyle(CS.ink)
            Spacer()
            Menu {
                Button { showingAddPlayer = true } label: {
                    Label("Add player", systemImage: "person.badge.plus")
                }
                Button { showingScanRoster = true } label: {
                    Label("Scan roster", systemImage: "camera.viewfinder")
                }
            } label: {
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

    // MARK: - Team sub-header

    private var subHeader: some View {
        HStack(spacing: 10) {
            TeamDisc(initials: team.monogram, color: team.accentColor, size: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(team.schoolName?.isEmpty == false ? team.schoolName! : team.name)
                    .font(.csUI(13, weight: .bold))
                    .foregroundStyle(CS.ink)
                Text(team.name)
                    .font(.csUI(10))
                    .foregroundStyle(CS.inkMute)
            }
            Spacer(minLength: 0)
            Text("\(teamPlayers.count) players")
                .font(.csMono(11, weight: .semibold))
                .foregroundStyle(CS.inkMute)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
    }

    // MARK: - Roster

    private var roster: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                subHeader

                sectionHeader("Active", count: activePlayers.count,
                              hint: "Tap a player to edit", dim: false)
                VStack(spacing: 4) {
                    ForEach(activePlayers) { player in
                        playerRow(player, dim: false)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)

                if !inactivePlayers.isEmpty {
                    sectionHeader("Inactive", count: inactivePlayers.count,
                                  hint: nil, dim: true)
                    VStack(spacing: 4) {
                        ForEach(inactivePlayers) { player in
                            playerRow(player, dim: true)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }

    private func sectionHeader(_ label: String, count: Int,
                               hint: String?, dim: Bool) -> some View {
        HStack {
            HStack(spacing: 8) {
                ShellSectionLabel(text: label)
                Text("\(count)")
                    .font(.csUI(10, weight: .heavy))
                    .foregroundStyle(dim ? CS.inkDim : CS.inkMute)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(CS.bgSoft, in: Capsule())
            }
            Spacer()
            if let hint {
                Text(hint)
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkDim)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func playerRow(_ player: Player, dim: Bool) -> some View {
        Button {
            editPlayer = player
        } label: {
            HStack(spacing: 12) {
                Jersey(number: player.jerseyNumber,
                       color: dim ? CS.inkMute : team.accentColor,
                       size: 36, dim: dim)
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.fullName)
                        .font(.csUI(14, weight: .bold))
                        .foregroundStyle(dim ? CS.inkMute : CS.ink)
                    Text("#\(player.jerseyNumber)")
                        .font(.csMono(11))
                        .foregroundStyle(CS.inkDim)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CS.inkDim)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(dim ? Color.clear : CS.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(dim ? Color.clear : CS.line, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 0) {
            subHeader
            VStack(spacing: 0) {
                HStack(spacing: -8) {
                    ForEach(0..<5, id: \.self) { _ in
                        Text("?")
                            .font(.csDisplay(14, weight: .heavy))
                            .foregroundStyle(CS.inkDim)
                            .frame(width: 36, height: 36)
                            .background(CS.bgSoft, in: Circle())
                            .overlay(Circle().strokeBorder(CS.lineStrong, lineWidth: 1.4))
                    }
                }
                .padding(.bottom, 18)

                Text("No players yet.")
                    .font(.csDisplay(22, weight: .heavy))
                    .foregroundStyle(CS.ink)
                Text("Add players manually, or snap a photo of the team's roster sheet and we'll pull out the numbers.")
                    .font(.csUI(13))
                    .foregroundStyle(CS.inkMute)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .padding(.horizontal, 8)

                VStack(spacing: 8) {
                    Button { showingAddPlayer = true } label: {
                        Text("ADD A PLAYER")
                            .font(.csDisplay(14, weight: .heavy))
                            .tracking(0.8)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(CS.brand, in: RoundedRectangle(cornerRadius: 12))
                    }
                    Button { showingScanRoster = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                            Text("Scan a roster sheet")
                        }
                        .font(.csUI(14, weight: .bold))
                        .foregroundStyle(CS.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(CS.bgCard, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(CS.lineStrong, lineWidth: 1.4)
                        )
                    }
                }
                .padding(.top, 18)
            }
            .padding(28)
            .background(CS.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(CS.lineStrong, style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
            )
            .padding(.horizontal, 22)
            .padding(.top, 28)

            Spacer()
        }
    }
}
