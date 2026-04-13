import SwiftUI
import SwiftData

struct RosterView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var team: Team
    @Query private var allPlayers: [Player]

    @State private var showingAddPlayer = false

    private var teamPlayers: [Player] {
        allPlayers.filter { $0.teamID == team.id }
    }

    private var sortedPlayers: [Player] {
        teamPlayers.sorted {
            let num0 = Int($0.jerseyNumber) ?? 999
            let num1 = Int($1.jerseyNumber) ?? 999
            return num0 < num1
        }
    }

    private var activePlayers: [Player] {
        sortedPlayers.filter { $0.isActive }
    }

    private var inactivePlayers: [Player] {
        sortedPlayers.filter { !$0.isActive }
    }

    var body: some View {
        List {
            Section("Active (\(activePlayers.count))") {
                ForEach(activePlayers) { player in
                    NavigationLink {
                        PlayerFormView(team: team, existingPlayer: player)
                    } label: {
                        PlayerRow(player: player)
                    }
                }
                .onDelete { offsets in
                    deletePlayers(from: activePlayers, at: offsets)
                }
            }

            if !inactivePlayers.isEmpty {
                Section("Inactive") {
                    ForEach(inactivePlayers) { player in
                        NavigationLink {
                            PlayerFormView(team: team, existingPlayer: player)
                        } label: {
                            PlayerRow(player: player)
                                .opacity(0.6)
                        }
                    }
                    .onDelete { offsets in
                        deletePlayers(from: inactivePlayers, at: offsets)
                    }
                }
            }
        }
        .navigationTitle("Roster")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddPlayer = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPlayer) {
            NavigationStack {
                PlayerFormView(team: team)
            }
        }
        .overlay {
            if teamPlayers.isEmpty {
                ContentUnavailableView {
                    Label("No Players", systemImage: "person")
                } description: {
                    Text("Add players to your roster.")
                } actions: {
                    Button("Add Player") {
                        showingAddPlayer = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func deletePlayers(from list: [Player], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(list[index])
        }
    }
}

struct PlayerRow: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(player.jerseyNumber)")
                .font(.headline)
                .fontWeight(.bold)
                .frame(width: 44, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.body)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
