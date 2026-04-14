import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: Binding(
                        get: { theme.isGymMode },
                        set: { theme.isGymMode = $0 }
                    )) {
                        HStack(spacing: 10) {
                            Image(systemName: theme.isGymMode ? "sun.max.fill" : "sun.max")
                                .foregroundStyle(theme.isGymMode ? .orange : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gym Mode")
                                Text("High-contrast, light appearance for bright gyms and outdoor games.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Appearance")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
