import SwiftUI
import SwiftData

struct TeamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Team.name)
    private var teams: [Team]

    @State private var showingAddTeam = false

    private let brandOrange = Color(hex: "#FF5E1A")

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            GeometryReader { proxy in
                Image("courtside-watermark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280)
                    .opacity(0.08)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.75)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                header

                List {
                    ForEach(teams) { team in
                        NavigationLink {
                            TeamDetailView(team: team)
                        } label: {
                            teamRow(team: team)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                    .onDelete(perform: deleteTeams)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }

            Text("Teams")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(brandOrange)

            Spacer()

            Button {
                showingAddTeam = true
            } label: {
                ZStack {
                    Circle()
                        .fill(brandOrange)
                        .frame(width: 40, height: 40)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Team Row

    private func teamRow(team: Team) -> some View {
        let accent: Color = {
            if let hex = team.colorHex {
                return TeamColor.from(hex: hex).color
            }
            return TeamColor.derived(from: team.id).color
        }()
        return HStack(spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(width: 4)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Text(initials(for: team.displayName))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(team.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("\(team.activePlayers.count) players")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    private func initials(for name: String) -> String {
        let words = name.split(separator: " ").prefix(2)
        let letters = words.compactMap { $0.first }.map(String.init)
        return letters.joined().uppercased()
    }

    private func deleteTeams(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(teams[index])
        }
    }
}
