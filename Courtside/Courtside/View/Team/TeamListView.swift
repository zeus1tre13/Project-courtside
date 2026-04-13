import SwiftUI
import SwiftData

struct TeamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Team.name)
    private var teams: [Team]

    @State private var showingAddTeam = false

    var body: some View {
        List {
            ForEach(teams) { team in
                NavigationLink {
                    TeamDetailView(team: team)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(team.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                        Text("\(team.activePlayers.count) players")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteTeams)
        }
        .navigationTitle("Teams")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddTeam = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTeam) {
            NavigationStack {
                TeamFormView()
            }
        }
        .overlay {
            if teams.isEmpty {
                ContentUnavailableView {
                    Label("No Teams", systemImage: "person.3")
                } description: {
                    Text("Add your first team to get started.")
                } actions: {
                    Button("Add Team") {
                        showingAddTeam = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func deleteTeams(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(teams[index])
        }
    }
}
