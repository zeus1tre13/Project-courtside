import SwiftUI

// ---------------------------------------------------------------------------
// App-shell components — the warm-paper system extended to the screens that
// wrap the game flow (home, teams, roster, settings).
// ---------------------------------------------------------------------------

/// The 12 team-identity colors offered in the color picker.
let teamColorSwatches: [String] = [
    "#1D6CFF", "#0EA5E9", "#0F766E", "#1AA46E",
    "#84CC16", "#E89B2A", "#E8492A", "#DC2626",
    "#EC4899", "#7C3AED", "#4338CA", "#14141A",
]

extension Team {
    /// Team identity color — the picked swatch, or home blue if unset.
    var accentColor: Color {
        colorHex.map { Color(hex: $0) } ?? CS.home
    }

    /// 1–2 letter monogram: first letter of school + first letter of name.
    var monogram: String {
        let school = (schoolName ?? "").trimmingCharacters(in: .whitespaces)
        let teamName = name.trimmingCharacters(in: .whitespaces)
        let letters = [school.first, teamName.first].compactMap { $0 }
        let result = String(letters).uppercased()
        return result.isEmpty ? "T" : result
    }
}

/// Initials disc — the team-identity sibling of `Jersey`.
struct TeamDisc: View {
    let initials: String
    var color: Color = CS.home
    var size: CGFloat = 36

    var body: some View {
        Text(initials)
            .font(.csDisplay(size * 0.42, weight: .heavy))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background {
                Circle().fill(Color.white)
                    .overlay(Circle().fill(color.opacity(0.14)))
            }
            .overlay(Circle().strokeBorder(color, lineWidth: 1.4))
    }
}

/// Win / loss badge. Green for wins, neutral gray for losses — never red.
struct WLPill: View {
    let win: Bool
    var margin: Int? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(win ? "W" : "L")
            if let margin {
                Text("· \(win ? "+" : "−")\(margin)").opacity(0.85)
            }
        }
        .font(.csDisplay(10, weight: .heavy))
        .tracking(1)
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(win ? CS.made : CS.missInk, in: Capsule())
    }
}

/// The small "COURTSIDE" lockup for screen chrome.
struct Wordmark: View {
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "basketball.fill")
                .font(.system(size: size))
            Text("COURTSIDE")
                .font(.csDisplay(size + 1, weight: .heavy))
                .tracking(1)
        }
        .foregroundStyle(CS.brand)
    }
}

/// 12-swatch team-color picker, 6×2. Selected swatch gets a white-rim halo.
struct ColorSwatchGrid: View {
    @Binding var selectedHex: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                  spacing: 10) {
            ForEach(teamColorSwatches, id: \.self) { hex in
                let isSelected = hex == selectedHex
                Button {
                    selectedHex = hex
                    HapticManager.selectionChanged()
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(Circle().strokeBorder(.white, lineWidth: isSelected ? 3 : 2))
                        .overlay {
                            if isSelected {
                                Circle().strokeBorder(Color(hex: hex), lineWidth: 2.5)
                                    .padding(-2.5)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Circle().strokeBorder(CS.ink.opacity(0.12), lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Consistent chrome for the shell's bottom sheets — grabber, a centered
/// display title, a leading (optional) and a trailing action.
struct ShellSheet<Content: View>: View {
    let title: String
    var leading: String? = "Cancel"
    var trailing: String
    var trailingEnabled: Bool = true
    var onLeading: () -> Void = {}
    var onTrailing: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(CS.lineStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            ZStack {
                Text(title)
                    .font(.csDisplay(17, weight: .heavy))
                    .foregroundStyle(CS.ink)
                HStack {
                    if let leading {
                        Button(leading, action: onLeading)
                            .font(.csUI(14, weight: .medium))
                            .foregroundStyle(CS.inkMute)
                    }
                    Spacer()
                    Button(trailing, action: onTrailing)
                        .font(.csUI(14, weight: .heavy))
                        .foregroundStyle(trailingEnabled ? CS.brand : CS.inkDim)
                        .disabled(!trailingEnabled)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .overlay(alignment: .bottom) { Rectangle().fill(CS.line).frame(height: 1) }

            ScrollView { content }
                .scrollIndicators(.hidden)
        }
        .background(CS.bgStage)
    }
}

/// A finished-game result row — W/L pill, opponent, score. Used on Home and
/// Team detail.
struct GameResultRow: View {
    let game: Game
    var teamLabel: String? = nil
    var action: () -> Void

    private var win: Bool { game.myTeamScore > game.opponentScore }
    private var margin: Int { abs(game.myTeamScore - game.opponentScore) }

    private var subline: String {
        let date = game.date.formatted(.dateTime.month(.abbreviated).day())
        return [teamLabel, date].compactMap { $0 }.joined(separator: " · ")
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                WLPill(win: win, margin: margin)
                VStack(alignment: .leading, spacing: 2) {
                    Text("vs \(game.opponentName.isEmpty ? "Opponent" : game.opponentName)")
                        .font(.csUI(14, weight: .bold))
                        .foregroundStyle(CS.ink)
                    Text(subline)
                        .font(.csUI(11))
                        .foregroundStyle(CS.inkMute)
                }
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Text("\(game.myTeamScore)")
                        .foregroundStyle(win ? CS.ink : CS.inkMute)
                    Text("–")
                        .font(.csUI(13))
                        .foregroundStyle(CS.inkDim)
                    Text("\(game.opponentScore)")
                        .foregroundStyle(win ? CS.inkMute : CS.ink)
                }
                .font(.csDisplay(22, weight: .heavy))
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CS.inkDim)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(CS.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CS.line, lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Uppercase small-caps section label.
struct ShellSectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.csUI(11, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(CS.inkDim)
    }
}

/// Wraps a row with iOS-style swipe-to-delete. We can't use SwiftUI's built-in
/// `.swipeActions` here because that modifier only works inside `List`, and the
/// home screen renders recent games as styled cards inside a `VStack`.
///
/// Drag from right to left to reveal a trailing Delete button. The button
/// invokes `onDelete`, which is expected to present its own confirmation.
struct SwipeToDeleteRow<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let actionWidth: CGFloat = 84
    private let cornerRadius: CGFloat = 12

    var body: some View {
        let totalOffset = max(-actionWidth * 1.4, min(0, offset + dragOffset))
        let revealed = -totalOffset

        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { offset = 0 }
                    onDelete()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Delete")
                            .font(.csUI(11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(revealed > 4 ? 1 : 0)
                .allowsHitTesting(revealed > 36)
            }
            .background(CS.danger)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            content()
                .background(CS.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .offset(x: totalOffset)
                .gesture(
                    DragGesture(minimumDistance: 12, coordinateSpace: .local)
                        .updating($dragOffset) { value, state, _ in
                            if abs(value.translation.width) > abs(value.translation.height) {
                                state = value.translation.width
                            }
                        }
                        .onEnded { value in
                            let predicted = value.predictedEndTranslation.width + offset
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                if predicted < -actionWidth / 2 {
                                    offset = -actionWidth
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if offset != 0 {
                            withAnimation(.easeOut(duration: 0.18)) { offset = 0 }
                        }
                    },
                    including: offset != 0 ? .all : .subviews
                )
        }
    }
}
