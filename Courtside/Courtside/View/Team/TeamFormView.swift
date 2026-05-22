import SwiftUI
import SwiftData

/// New / edit team — a sheet with a live-preview disc and a 12-color picker.
/// Edit mode adds a destructive Delete-team action.
struct TeamFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingTeam: Team?

    @State private var schoolName = ""
    @State private var name = ""
    @State private var selectedHex = "#1D6CFF"
    @State private var showingDeleteConfirm = false

    private var isEditing: Bool { existingTeam != nil }
    private var canSave: Bool {
        !schoolName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var previewInitials: String {
        let s = schoolName.trimmingCharacters(in: .whitespaces)
        let n = name.trimmingCharacters(in: .whitespaces)
        let letters = [s.first, n.first].compactMap { $0 }
        let result = String(letters).uppercased()
        return result.isEmpty ? "T" : result
    }

    var body: some View {
        ShellSheet(
            title: isEditing ? "Edit team" : "New team",
            trailing: isEditing ? "Save" : "Create",
            trailingEnabled: canSave,
            onLeading: { dismiss() },
            onTrailing: { save() }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                preview
                formField("School / org", required: true) {
                    TextField("e.g. Colby HS", text: $schoolName)
                        .textContentType(.organizationName)
                }
                formField("Team name", sub: "optional",
                          hint: "Distinguishes JV from Varsity, boys from girls, etc.") {
                    TextField("e.g. Eagles · Varsity", text: $name)
                }
                VStack(alignment: .leading, spacing: 8) {
                    ShellSectionLabel(text: "Team color")
                    ColorSwatchGrid(selectedHex: $selectedHex)
                }

                if isEditing {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Delete team")
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
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .onAppear {
            if let existingTeam {
                schoolName = existingTeam.schoolName ?? ""
                name = existingTeam.name
                selectedHex = existingTeam.colorHex ?? "#1D6CFF"
            }
        }
        .alert("Delete team?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteTeam() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the team and its roster. Past games are kept.")
        }
    }

    // MARK: - Preview

    private var preview: some View {
        HStack(spacing: 14) {
            TeamDisc(initials: previewInitials, color: Color(hex: selectedHex), size: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text("LIVE PREVIEW")
                    .font(.csUI(10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(CS.inkDim)
                Text(schoolName.isEmpty ? "Your team" : schoolName)
                    .font(.csDisplay(20, weight: .heavy))
                    .foregroundStyle(CS.ink)
                    .lineLimit(1)
                Text(name.isEmpty ? "How the team appears everywhere" : name)
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkMute)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(hex: selectedHex).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(hex: selectedHex).opacity(0.35), lineWidth: 1.4)
        )
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
                    Text(sub)
                        .font(.csUI(10))
                        .foregroundStyle(CS.inkDim)
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
                Text(hint)
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkMute)
            }
        }
    }

    // MARK: - Persistence

    private func save() {
        let school = schoolName.trimmingCharacters(in: .whitespaces)
        let teamName = name.trimmingCharacters(in: .whitespaces)
        guard !school.isEmpty else { return }

        if let existingTeam {
            existingTeam.schoolName = school
            existingTeam.name = teamName
            existingTeam.colorHex = selectedHex
        } else {
            let team = Team(
                name: teamName,
                schoolName: school,
                isMyTeam: true,
                colorHex: selectedHex
            )
            modelContext.insert(team)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteTeam() {
        if let existingTeam {
            modelContext.delete(existingTeam)
            try? modelContext.save()
        }
        dismiss()
    }
}
