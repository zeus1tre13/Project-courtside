import SwiftUI

/// Jersey-number disc — a number on a colored circle. Replaces generic
/// avatars throughout the redesign. `dim` is the bench / inactive variant.
struct Jersey: View {
    let number: String
    var color: Color = CS.home
    var size: CGFloat = 36
    var dim: Bool = false

    var body: some View {
        Text(number)
            .font(.csDisplay(size * 0.46, weight: .heavy))
            .foregroundStyle(dim ? CS.inkMute : color)
            .frame(width: size, height: size)
            .background {
                Circle().fill(Color.white)
                    .overlay(Circle().fill(dim ? CS.bgSoft : color.opacity(0.14)))
            }
            .overlay(
                Circle().strokeBorder(dim ? CS.lineStrong : color, lineWidth: 1.4)
            )
    }
}
