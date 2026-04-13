import SwiftUI
import SwiftData

struct PlayerFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let team: Team
    var existingPlayer: Player?

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var jerseyNumber: String = ""
    @State private var isActive: Bool = true

    var isEditing: Bool { existingPlayer != nil }

    var body: some View {
        Form {
            Section("Player Info") {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .autocorrectionDisabled()
                TextField("Jersey Number", text: $jerseyNumber)
                    .keyboardType(.numberPad)
            }

            if isEditing {
                Section {
                    Toggle("Active", isOn: $isActive)
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Player" : "Add Player")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    savePlayer()
                }
                .disabled(!isFormValid)
            }
        }
        .onAppear {
            if let existingPlayer {
                firstName = existingPlayer.firstName
                lastName = existingPlayer.lastName
                jerseyNumber = existingPlayer.jerseyNumber
                isActive = existingPlayer.isActive
            }
        }
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !jerseyNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func savePlayer() {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespaces)
        let trimmedNumber = jerseyNumber.trimmingCharacters(in: .whitespaces)

        if let existingPlayer {
            existingPlayer.firstName = trimmedFirst
            existingPlayer.lastName = trimmedLast
            existingPlayer.jerseyNumber = trimmedNumber
            existingPlayer.isActive = isActive
        } else {
            let player = Player(
                firstName: trimmedFirst,
                lastName: trimmedLast,
                jerseyNumber: trimmedNumber
            )
            player.teamID = team.id
            modelContext.insert(player)
        }

        dismiss()
    }
}
