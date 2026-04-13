import SwiftUI

struct QuickAddOpponentView: View {
    @Bindable var viewModel: LiveGameViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var jerseyNumber = ""
    @State private var firstName = ""
    @State private var lastName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Add Opponent Player") {
                    TextField("Jersey #", text: $jerseyNumber)
                        .keyboardType(.numberPad)
                    TextField("First Name", text: $firstName)
                        .autocorrectionDisabled()
                    TextField("Last Name", text: $lastName)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Add Opponent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addOpponentPlayer(
                            firstName: firstName.trimmingCharacters(in: .whitespaces),
                            lastName: lastName.trimmingCharacters(in: .whitespaces),
                            jerseyNumber: jerseyNumber.trimmingCharacters(in: .whitespaces)
                        )
                        dismiss()
                    }
                    .disabled(jerseyNumber.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
}
