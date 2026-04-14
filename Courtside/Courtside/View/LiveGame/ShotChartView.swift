import SwiftUI

struct ShotChartView: View {
    let validZones: [ShotZone]
    let onZoneSelected: (ShotZone) -> Void
    let onCancel: () -> Void

    @State private var highlightedZone: ShotZone?

    private var headerText: String {
        if validZones.first?.isThreePointZone == true {
            return "Where was the 3?"
        } else {
            return "Where was the shot?"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(headerText)
                    .font(.headline)
                Spacer()
                Button("Cancel") { onCancel() }
                    .font(.subheadline)
            }
            .padding(.horizontal)

            GeometryReader { geo in
                let width = geo.size.width
                let height = width * 0.85

                ZStack {
                    // Court floor
                    CourtFill()
                        .fill(Color(.systemGray6))
                        .frame(width: width, height: height)

                    // Court lines
                    CourtShape()
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: width, height: height)

                    // Tappable zones — only valid ones are active
                    ForEach(ShotZone.allCases, id: \.self) { zone in
                        let isValid = validZones.contains(zone)
                        let rect = zone.hitArea
                        let zoneRect = CGRect(
                            x: rect.origin.x * width,
                            y: rect.origin.y * height,
                            width: rect.width * width,
                            height: rect.height * height
                        )

                        if isValid {
                            ZoneButton(
                                zone: zone,
                                rect: zoneRect,
                                isHighlighted: highlightedZone == zone
                            ) {
                                highlightedZone = zone
                                HapticManager.selectionChanged()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    onZoneSelected(zone)
                                }
                            }
                        } else {
                            // Dimmed, non-tappable zone
                            Text(zone.shortLabel)
                                .font(.system(size: 12, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.tertiary)
                                .frame(width: zoneRect.width, height: zoneRect.height)
                                .position(x: zoneRect.midX, y: zoneRect.midY)
                        }
                    }
                }
                .frame(width: width, height: height)
            }
            .aspectRatio(1 / 0.85, contentMode: .fit)
            .padding(.horizontal)
        }
    }
}

// MARK: - Zone Button

private struct ZoneButton: View {
    let zone: ShotZone
    let rect: CGRect
    let isHighlighted: Bool
    let action: () -> Void

    private var fillColor: Color {
        if isHighlighted { return .orange }
        return zone.isThreePointZone ? Color.blue.opacity(0.12) : Color.orange.opacity(0.12)
    }

    private var borderColor: Color {
        zone.isThreePointZone ? Color.blue.opacity(0.3) : Color.orange.opacity(0.3)
    }

    var body: some View {
        Button(action: action) {
            Text(zone.shortLabel)
                .font(.system(size: 13, weight: .semibold))
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .foregroundStyle(isHighlighted ? .white : .primary)
                .frame(width: rect.width, height: rect.height)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(fillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .position(
            x: rect.midX,
            y: rect.midY
        )
    }
}

// MARK: - Court Shape (lines only)

private struct CourtShape: Shape {
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

private struct CourtFill: Shape {
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
