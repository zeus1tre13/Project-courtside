import SwiftUI
import SwiftData

/// Add / edit player — a sheet with a live jersey-number preview. The Active
/// toggle and the destructive Remove action show only in edit mode.
struct PlayerFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let team: Team
    var existingPlayer: Player?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var jerseyNumber = ""
    @State private var isActive = true
    @State private var showingRemoveConfirm = false

    private var isEditing: Bool { existingPlayer != nil }
    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !jerseyNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ShellSheet(
            title: isEditing ? "Edit player" : "Add player",
            trailing: isEditing ? "Save" : "Add",
            trailingEnabled: isValid,
            onLeading: { dismiss() },
            onTrailing: { save() }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                preview

                HStack(spacing: 10) {
                    formField("First name", required: true) {
                        TextField("First", text: $firstName)
                    }
                    formField("Last name", required: true) {
                        TextField("Last", text: $lastName)
                    }
                }

                formField("Jersey number", sub: "0–99", required: true,
                          hint: "Shown as a disc throughout the app.") {
                    TextField("00", text: $jerseyNumber)
                        .keyboardType(.numberPad)
                        .font(.csMono(22, weight: .bold))
                }

                if isEditing {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Active")
                                .font(.csUI(14, weight: .bold))
                                .foregroundStyle(CS.ink)
                            Text("Inactive players don't appear in the floor-5 picker — useful for injured or absent.")
                                .font(.csUI(11))
                                .foregroundStyle(CS.inkMute)
                        }
                        Spacer(minLength: 0)
                        Toggle("", isOn: $isActive)
                            .labelsHidden()
                            .tint(CS.made)
                    }
                    .padding(14)
                    .background(CS.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))

                    Button(role: .destructive) {
                        showingRemoveConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Remove from roster")
                        }
                        .font(.csUI(14, weight: .bold))
                        .foregroundStyle(CS.danger)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(CS.danger.opacity(0.35), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .onAppear {
            if let existingPlayer {
                firstName = existingPlayer.firstName
                lastName = existingPlayer.lastName
                jerseyNumber = existingPlayer.jerseyNumber
                isActive = existingPlayer.isActive
            }
        }
        .alert("Remove player?", isPresented: $showingRemoveConfirm) {
            Button("Remove", role: .destructive) { removePlayer() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the player from the roster. Past game stats are kept.")
        }
    }

    // MARK: - Preview

    private var preview: some View {
        let number = jerseyNumber.trimmingCharacters(in: .whitespaces)
        let hasNumber = !number.isEmpty
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return HStack(spacing: 18) {
            Text(hasNumber ? number : "—")
                .font(.csDisplay(40, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(hasNumber ? team.accentColor : CS.inkDim)
                .frame(width: 84, height: 84)
                .background {
                    Circle().fill(Color.white)
                        .overlay(Circle().fill(
                            hasNumber ? team.accentColor.opacity(0.14) : CS.bgSoft))
                }
                .overlay(
                    Circle().strokeBorder(
                        hasNumber ? team.accentColor : CS.lineStrong, lineWidth: 1.4)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text("LIVE PREVIEW")
                    .font(.csUI(10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(CS.inkDim)
                Text(name.isEmpty ? "New player" : name)
                    .font(.csDisplay(22, weight: .heavy))
                    .foregroundStyle(CS.ink)
                    .lineLimit(1)
                Text(team.displayName)
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkMute)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(CS.line, lineWidth: 1))
    }

    // MARK: - Field

    private func formField<Content: View>(_ label: String, sub: String? = nil,
                                          required: Bool = false, hint: String? = nil,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 2) {
                    ShellSectionLabel(text: label)
                    if required {
                        Text("*").font(.csUI(11, weight: .bold)).foregroundStyle(CS.brand)
                    }
                }
                Spacer()
                if let sub {
                    Text(sub).font(.csUI(10)).foregroundStyle(CS.inkDim)
                }
            }
            content()
                .font(.csUI(16, weight: .semibold))
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(CS.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(CS.lineStrong, lineWidth: 1)
                )
            if let hint {
                Text(hint).font(.csUI(11)).foregroundStyle(CS.inkMute)
            }
        }
    }

    // MARK: - Persistence

    private func save() {
        let first = firstName.trimmingCharacters(in: .whitespaces)
        let last = lastName.trimmingCharacters(in: .whitespaces)
        let number = jerseyNumber.trimmingCharacters(in: .whitespaces)
        guard !first.isEmpty, !last.isEmpty, !number.isEmpty else { return }

        if let existingPlayer {
            existingPlayer.firstName = first
            existingPlayer.lastName = last
            existingPlayer.jerseyNumber = number
            existingPlayer.isActive = isActive
        } else {
            let player = Player(firstName: first, lastName: last, jerseyNumber: number)
            player.teamID = team.id
            modelContext.insert(player)
        }
        try? modelContext.save()
        dismiss()
    }

    private func removePlayer() {
        if let existingPlayer {
            modelContext.delete(existingPlayer)
            try? modelContext.save()
        }
        dismiss()
    }
}
