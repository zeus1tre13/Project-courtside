import SwiftUI
import SwiftData

struct TeamFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingTeam: Team?

    @State private var name: String = ""
    @State private var schoolName: String = ""
    @State private var selectedColor: TeamColor = .blue

    var isEditing: Bool { existingTeam != nil }

    var body: some View {
        Form {
            Section("Team Info") {
                TextField("School / Organization", text: $schoolName)
                    .textContentType(.organizationName)
                TextField("Team Name (e.g. Varsity, JV) — optional", text: $name)
                    .textContentType(.organizationName)
            }

            Section("Team Color") {
                colorPicker
                    .padding(.vertical, 4)
            }
        }
        .navigationTitle(isEditing ? "Edit Team" : "New Team")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Create") {
                    saveTeam()
                }
                .disabled(schoolName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let existingTeam {
                name = existingTeam.name
                schoolName = existingTeam.schoolName ?? ""
                if let hex = existingTeam.colorHex {
                    selectedColor = TeamColor.from(hex: hex)
                } else {
                    selectedColor = TeamColor.derived(from: existingTeam.id)
                }
            }
        }
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6),
            spacing: 12
        ) {
            ForEach(TeamColor.allCases) { option in
                Button {
                    selectedColor = option
                } label: {
                    ZStack {
                        Circle()
                            .fill(option.color)
                            .frame(width: 36, height: 36)

                        if selectedColor == option {
                            Circle()
                                .strokeBorder(Color(.systemBackground), lineWidth: 3)
                                .frame(width: 36, height: 36)
                            Circle()
                                .strokeBorder(option.color, lineWidth: 2)
                                .frame(width: 42, height: 42)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.displayName)
                .accessibilityAddTraits(selectedColor == option ? [.isSelected] : [])
            }
        }
    }

    // MARK: - Persistence

    private func saveTeam() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedSchool = schoolName.trimmingCharacters(in: .whitespaces)

        // School is required, team name is optional
        let teamName = trimmedName.isEmpty ? trimmedSchool : trimmedName

        if let existingTeam {
            existingTeam.name = teamName
            existingTeam.schoolName = trimmedSchool
            existingTeam.colorHex = selectedColor.hex
        } else {
            let team = Team(
                name: teamName,
                schoolName: trimmedSchool,
                isMyTeam: true,
                colorHex: selectedColor.hex
            )
            modelContext.insert(team)
        }

        try? modelContext.save()
        dismiss()
    }
}
