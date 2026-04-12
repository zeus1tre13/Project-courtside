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
                TextField("Team Name", text: $name)
                    .textContentType(.organizationName)
                TextField("School / Organization (optional)", text: $schoolName)
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
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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

        if let existingTeam {
            existingTeam.name = trimmedName
            existingTeam.schoolName = trimmedSchool.isEmpty ? nil : trimmedSchool
        } else {
            let team = Team(
                name: trimmedName,
                schoolName: trimmedSchool.isEmpty ? nil : trimmedSchool,
                isMyTeam: true
            )
            modelContext.insert(team)
        }

        dismiss()
    }
}
