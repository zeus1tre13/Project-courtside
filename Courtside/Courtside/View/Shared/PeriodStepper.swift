import SwiftUI

/// Q1·Q2·Q3·Q4 segmented period control. Replaces the hidden "Next" pill —
/// the current period is filled ink, the rest are tappable.
struct PeriodStepper: View {
    let count: Int
    let current: Int
    var onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...max(count, current), id: \.self) { period in
                Button {
                    onSelect(period)
                } label: {
                    Text("\(period)")
                        .font(.csUI(11, weight: .bold))
                        .foregroundStyle(period == current ? Color.white : CS.inkMute)
                        .frame(width: 22, height: 22)
                        .background(period == current ? CS.ink : Color.clear)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(CS.bgSoft)
        .clipShape(Capsule())
    }
}
