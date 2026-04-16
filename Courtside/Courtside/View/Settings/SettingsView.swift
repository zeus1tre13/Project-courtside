import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    private static let privacyURL = URL(string: "https://xciv.ai/courtside/privacy.html")!
    private static let supportURL = URL(string: "https://xciv.ai/courtside/support.html")!

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

                Section {
                    Link(destination: Self.supportURL) {
                        Label("Contact Support", systemImage: "lifepreserver")
                    }
                    Link(destination: Self.privacyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                } header: {
                    Text("Help & Privacy")
                }

                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Self.appVersionString)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } header: {
                    Text("About")
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

    // MARK: - Version string

    private static var appVersionString: String {
        let info = Bundle.main.infoDictionary
        let marketing = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(marketing) (\(build))"
    }
}
