import SwiftUI

/// Live-game shot-zone picker — the 12-chip half-court. The same 12 zones
/// appear for 2PT and 3PT; only zones valid for the shot type are tappable.
/// "Skip" commits the shot without a zone, for fast play.
struct ShotChartView: View {
    let validZones: [ShotZone]
    var playerLabel: String = ""
    let onZoneSelected: (ShotZone) -> Void
    let onCancel: () -> Void

    @State private var selected: ShotZone?

    private var isThree: Bool {
        validZones.first?.isThreePointZone == true
    }

    var body: some View {
        VStack(spacing: 10) {
            header

            HalfCourtChart(paintFill: CS.amber.opacity(0.08)) { zone in
                zoneChip(zone)
            }
            .padding(.horizontal, 12)

            Text("Same 12 zones for 2PT & 3PT · FT commits without a zone")
                .font(.csUI(10))
                .foregroundStyle(CS.inkDim)
        }
        .padding(.vertical, 14)
        .background(CS.bgStage)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(isThree ? "3PT" : "2PT")\(playerLabel.isEmpty ? "" : " · \(playerLabel)")")
                    .font(.csUI(10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(CS.home)
                Text(isThree ? "Where was the 3?" : "Where was the shot?")
                    .font(.csDisplay(20, weight: .bold))
                    .foregroundStyle(CS.ink)
            }
            Spacer()
            Button { onCancel() } label: {
                Text("SKIP")
                    .font(.csUI(11, weight: .heavy))
                    .tracking(0.6)
                    .foregroundStyle(CS.inkMute)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(CS.bgSoft, in: Capsule())
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func zoneChip(_ zone: ShotZone) -> some View {
        let valid = validZones.contains(zone)
        let isSelected = selected == zone
        let tint = zone.isThreePointZone ? CS.away : CS.amber
        Button {
            guard valid else { return }
            selected = zone
            HapticManager.selectionChanged()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onZoneSelected(zone)
            }
        } label: {
            HStack(spacing: 3) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                }
                Text(zone.shortLabel)
            }
            .font(.csUI(11, weight: .bold))
            .foregroundStyle(isSelected ? .white : CS.ink)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background {
                Color.white
                (isSelected ? CS.made : tint.opacity(0.13))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? CS.made : tint.opacity(0.5), lineWidth: 1.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(CS.made.opacity(isSelected ? 0.25 : 0), lineWidth: 4)
            )
        }
        .buttonStyle(.plain)
        .opacity(valid ? 1 : 0.32)
        .disabled(!valid)
    }
}

// MARK: - Court Shape (lines only)
// Retained for ShotCourtDisplayView (season analytics court).

struct CourtShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        // Court outline
        p.addRect(rect)

        // Paint / lane (centered, 12ft wide ≈ 24% of 50ft court width)
        let laneW = w * 0.24
        let laneH = h * 0.36
        let laneX = (w - laneW) / 2
        let laneRect = CGRect(x: laneX, y: 0, width: laneW, height: laneH)
        p.addRect(laneRect)

        // Free throw circle
        let ftCenterX = w / 2
        let ftCenterY = laneH
        let ftRadius = laneW / 2
        p.addEllipse(in: CGRect(
            x: ftCenterX - ftRadius,
            y: ftCenterY - ftRadius,
            width: ftRadius * 2,
            height: ftRadius * 2
        ))

        // Basket circle
        let basketY: CGFloat = h * 0.03
        let basketR: CGFloat = w * 0.015
        p.addEllipse(in: CGRect(
            x: w / 2 - basketR,
            y: basketY - basketR,
            width: basketR * 2,
            height: basketR * 2
        ))

        // Backboard
        let bbW = w * 0.06
        p.move(to: CGPoint(x: w / 2 - bbW / 2, y: h * 0.015))
        p.addLine(to: CGPoint(x: w / 2 + bbW / 2, y: h * 0.015))

        // Restricted area arc
        let raRadius = w * 0.04
        p.addArc(
            center: CGPoint(x: w / 2, y: h * 0.03),
            radius: raRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Three-point arc
        let arcCenterY = h * 0.03
        let arcRadius = w * 0.40
        let cornerLineX = w * 0.065

        // Left corner line
        p.move(to: CGPoint(x: cornerLineX, y: 0))
        p.addLine(to: CGPoint(x: cornerLineX, y: h * 0.28))

        // Arc
        let startAngle = acos((w / 2 - cornerLineX) / arcRadius)
        p.addArc(
            center: CGPoint(x: w / 2, y: arcCenterY),
            radius: arcRadius,
            startAngle: Angle(radians: .pi / 2 + startAngle),
            endAngle: Angle(radians: .pi / 2 - startAngle),
            clockwise: true
        )

        // Right corner line
        p.move(to: CGPoint(x: w - cornerLineX, y: 0))
        p.addLine(to: CGPoint(x: w - cornerLineX, y: h * 0.28))

        // Half-court line
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: w, y: h))

        // Center circle (half)
        let ccRadius = w * 0.12
        p.addArc(
            center: CGPoint(x: w / 2, y: h),
            radius: ccRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        return p
    }
}

// MARK: - Court Fill

struct CourtFill: Shape {
    func path(in rect: CGRect) -> Path {
        Path(rect)
    }
}

// MARK: - Short Labels for Zones

extension ShotZone {
    var shortLabel: String {
        switch self {
        case .paintLeft: return "Paint L"
        case .paintRight: return "Paint R"
        case .midLeftBaseline: return "Baseline L"
        case .midLeftElbow: return "Elbow L"
        case .midFreeThrow: return "FT"
        case .midRightElbow: return "Elbow R"
        case .midRightBaseline: return "Baseline R"
        case .threeLeftCorner: return "Corner L"
        case .threeLeftWing: return "Wing L"
        case .threeTopOfKey: return "Top"
        case .threeRightWing: return "Wing R"
        case .threeRightCorner: return "Corner R"
        }
    }
}
