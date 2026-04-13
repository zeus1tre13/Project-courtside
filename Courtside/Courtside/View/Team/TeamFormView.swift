import SwiftUI
import SwiftData

struct TeamFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingTeam: Team?

    @State private var name: String = ""
    @State private var schoolName: String = ""

    var isEditing: Bool { existingTeam != nil }

    var body: some View {
        Form {
            Section("Team Info") {
                TextField("School / Organization", text: $schoolName)
                    .textContentType(.organizationName)
                TextField("Team Name (e.g. Varsity, JV) — optional", text: $name)
                    .textContentType(.organizationName)
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
            }
        }
    }

    private func saveTeam() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedSchool = schoolName.trimmingCharacters(in: .whitespaces)

        // School is required, team name is optional
        let teamName = trimmedName.isEmpty ? trimmedSchool : trimmedName

        if let existingTeam {
            existingTeam.name = teamName
            existingTeam.schoolName = trimmedSchool
        } else {
            let team = Team(
                name: teamName,
                schoolName: trimmedSchool,
                isMyTeam: true
            )
            modelContext.insert(team)
        }

        try? modelContext.save()
        dismiss()
    }
}
