import SwiftUI

/// Settings — a warm-paper card sheet. Two scoring toggles, two links,
/// a version row.
struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @AppStorage("assistPromptDefault") private var promptForAssists = true

    private static let privacyURL = URL(string: "https://xciv.ai/courtside/privacy.html")!
    private static let supportURL = URL(string: "https://xciv.ai/courtside/support.html")!

    var body: some View {
        ShellSheet(
            title: "Settings",
            leading: nil,
            trailing: "Done",
            onTrailing: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                section("Scoring") {
                    toggleRow(
                        "Gym mode",
                        "High-contrast, light appearance for bright gyms.",
                        isOn: Binding(get: { theme.isGymMode },
                                      set: { theme.isGymMode = $0 })
                    )
                    Divider().background(CS.line)
                    toggleRow(
                        "Prompt for assists",
                        "After a made 2PT or 3PT, ask who passed.",
                        isOn: $promptForAssists
                    )
                }

                section("Help & info") {
                    Link(destination: Self.supportURL) {
                        linkRow("envelope", "Contact support", "We usually reply the same day")
                    }
                    Divider().background(CS.line)
                    Link(destination: Self.privacyURL) {
                        linkRow("hand.raised", "Privacy policy", "What we collect (almost nothing)")
                    }
                }

                versionCard
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Pieces

    private func section<Content: View>(_ label: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ShellSectionLabel(text: label)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 14)
                .background(CS.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
        }
    }

    private func toggleRow(_ title: String, _ desc: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.csUI(14, weight: .bold))
                    .foregroundStyle(CS.ink)
                Text(desc)
                    .font(.csUI(12))
                    .foregroundStyle(CS.inkMute)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(CS.made)
        }
        .padding(.vertical, 14)
    }

    private func linkRow(_ icon: String, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(CS.brand)
                .frame(width: 32, height: 32)
                .background(CS.brandSoft, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.csUI(14, weight: .bold))
                    .foregroundStyle(CS.ink)
                Text(sub)
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkMute)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(CS.inkDim)
        }
        .padding(.vertical, 12)
    }

    private var versionCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "basketball.fill")
                .font(.system(size: 18))
                .foregroundStyle(CS.brand)
                .frame(width: 36, height: 36)
                .background(CS.brandSoft, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 1) {
                Text("Courtside")
                    .font(.csDisplay(15, weight: .heavy))
                    .foregroundStyle(CS.ink)
                Text("Built by XCIV.ai")
                    .font(.csUI(11))
                    .foregroundStyle(CS.inkMute)
            }
            Spacer(minLength: 0)
            Text(Self.appVersionString)
                .font(.csMono(12))
                .foregroundStyle(CS.inkMute)
        }
        .padding(14)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
    }

    private static var appVersionString: String {
        let info = Bundle.main.infoDictionary
        let marketing = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "v\(marketing) · \(build)"
    }
}
