import SwiftUI

// ---------------------------------------------------------------------------
// Half-court geometry — real basketball-court proportions.
// 50ft × 47ft court → 1000 × 940 reference space. Basket at the top,
// half-court line at the bottom. Shared by the live-game zone picker and
// the post-game shot-chart heat map.
// ---------------------------------------------------------------------------

enum CourtGeometry {
    static let w: CGFloat = 1000
    static let h: CGFloat = 940
    static let cx: CGFloat = 500
    static let basketY: CGFloat = 105      // 5.25ft from baseline
    static let arcRadius: CGFloat = 475    // 23.75ft three-point arc
    static let cornerX: CGFloat = 60       // corner-3 straight portion
    static let paintWidth: CGFloat = 320
    static let paintHeight: CGFloat = 380  // baseline → FT line
    static let ftRadius: CGFloat = 120
    static let restrictedRadius: CGFloat = 80

    static var paintX: CGFloat { cx - paintWidth / 2 }
    static var cornerTopY: CGFloat {
        basketY + sqrt(arcRadius * arcRadius - (cx - cornerX) * (cx - cornerX))
    }

    /// Sample an arc as a point list (screen coords: 0° = +x, 90° = down).
    static func arc(center: CGPoint, radius: CGFloat,
                    startDeg: Double, endDeg: Double, steps: Int = 56) -> [CGPoint] {
        (0...steps).map { i in
            let t = Double(i) / Double(steps)
            let rad = (startDeg + (endDeg - startDeg) * t) * .pi / 180
            return CGPoint(x: center.x + radius * CGFloat(cos(rad)),
                           y: center.y + radius * CGFloat(sin(rad)))
        }
    }
}

/// Solid court lines.
struct HalfCourt: Shape {
    func path(in rect: CGRect) -> Path {
        let g = CourtGeometry.self
        func s(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + p.x / g.w * rect.width,
                    y: rect.minY + p.y / g.h * rect.height)
        }
        var path = Path()

        // Half-court line
        path.move(to: s(CGPoint(x: 0, y: g.h)))
        path.addLine(to: s(CGPoint(x: g.w, y: g.h)))

        // Corner-3 straight lines
        path.move(to: s(CGPoint(x: g.cornerX, y: 0)))
        path.addLine(to: s(CGPoint(x: g.cornerX, y: g.cornerTopY)))
        path.move(to: s(CGPoint(x: g.w - g.cornerX, y: 0)))
        path.addLine(to: s(CGPoint(x: g.w - g.cornerX, y: g.cornerTopY)))

        // Three-point arc
        let basket = CGPoint(x: g.cx, y: g.basketY)
        let angL = atan2(g.cornerTopY - g.basketY, g.cornerX - g.cx) * 180 / .pi
        let angR = atan2(g.cornerTopY - g.basketY, (g.w - g.cornerX) - g.cx) * 180 / .pi
        addPolyline(&path, g.arc(center: basket, radius: g.arcRadius,
                                 startDeg: angL, endDeg: angR).map(s))

        // Paint
        path.addRect(CGRect(x: g.paintX, y: 0, width: g.paintWidth, height: g.paintHeight)
            .applying(scale(in: rect)))

        // FT circle — solid top half
        addPolyline(&path, g.arc(center: CGPoint(x: g.cx, y: g.paintHeight),
                                 radius: g.ftRadius, startDeg: 180, endDeg: 360).map(s))

        // Backboard
        path.move(to: s(CGPoint(x: g.cx - 36, y: 80)))
        path.addLine(to: s(CGPoint(x: g.cx + 36, y: 80)))

        // Rim
        let rimR = 16 / g.w * rect.width
        path.addEllipse(in: CGRect(x: s(basket).x - rimR, y: s(basket).y - rimR,
                                   width: rimR * 2, height: rimR * 2))

        // Restricted-area arc
        addPolyline(&path, g.arc(center: basket, radius: g.restrictedRadius,
                                 startDeg: 0, endDeg: 180).map(s))
        return path
    }

    private func scale(in rect: CGRect) -> CGAffineTransform {
        CGAffineTransform(scaleX: rect.width / CourtGeometry.w,
                          y: rect.height / CourtGeometry.h)
            .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY))
    }

    private func addPolyline(_ path: inout Path, _ points: [CGPoint]) {
        guard let first = points.first else { return }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
    }
}

/// Dashed court lines (FT-jumper half of the circle, half-court center circle).
struct HalfCourtDashed: Shape {
    func path(in rect: CGRect) -> Path {
        let g = CourtGeometry.self
        func s(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + p.x / g.w * rect.width,
                    y: rect.minY + p.y / g.h * rect.height)
        }
        var path = Path()

        let ftBottom = g.arc(center: CGPoint(x: g.cx, y: g.paintHeight),
                             radius: g.ftRadius, startDeg: 0, endDeg: 180).map(s)
        polyline(&path, ftBottom)

        let center = g.arc(center: CGPoint(x: g.cx, y: g.h),
                           radius: 120, startDeg: 180, endDeg: 360).map(s)
        polyline(&path, center)
        return path
    }

    private func polyline(_ path: inout Path, _ points: [CGPoint]) {
        guard let first = points.first else { return }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
    }
}

/// The painted lane rectangle — fillable separately from the line work.
struct HalfCourtPaint: Shape {
    func path(in rect: CGRect) -> Path {
        let g = CourtGeometry.self
        let r = CGRect(x: g.paintX / g.w * rect.width + rect.minX,
                       y: rect.minY,
                       width: g.paintWidth / g.w * rect.width,
                       height: g.paintHeight / g.h * rect.height)
        return Path(r)
    }
}

extension ShotZone {
    /// Normalized center (0...1) of this zone's chip on the half-court.
    var courtPosition: CGPoint {
        switch self {
        case .paintLeft:        return CGPoint(x: 0.425, y: 0.175)
        case .paintRight:       return CGPoint(x: 0.575, y: 0.175)
        case .midLeftBaseline:  return CGPoint(x: 0.225, y: 0.11)
        case .midLeftElbow:     return CGPoint(x: 0.27,  y: 0.30)
        case .midFreeThrow:     return CGPoint(x: 0.50,  y: 0.46)
        case .midRightElbow:    return CGPoint(x: 0.73,  y: 0.30)
        case .midRightBaseline: return CGPoint(x: 0.775, y: 0.11)
        case .threeLeftCorner:  return CGPoint(x: 0.06,  y: 0.125)
        case .threeLeftWing:    return CGPoint(x: 0.11,  y: 0.46)
        case .threeTopOfKey:    return CGPoint(x: 0.50,  y: 0.72)
        case .threeRightWing:   return CGPoint(x: 0.89,  y: 0.46)
        case .threeRightCorner: return CGPoint(x: 0.94,  y: 0.125)
        }
    }
}

/// Half-court canvas with a caller-supplied view positioned over each of the
/// 12 zones. Used by the heat map and the live-game zone picker.
struct HalfCourtChart<ZoneContent: View>: View {
    var paintFill: Color = .clear
    @ViewBuilder var zoneContent: (ShotZone) -> ZoneContent

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(CS.bgStage)
                HalfCourtPaint().fill(paintFill)
                HalfCourt().stroke(CS.ink.opacity(0.3), lineWidth: 2)
                HalfCourtDashed().stroke(
                    CS.ink.opacity(0.18),
                    style: StrokeStyle(lineWidth: 2, dash: [7, 7])
                )
                // Rim accent
                HalfCourtRim().stroke(CS.brand, lineWidth: 2.5)

                ForEach(ShotZone.allCases, id: \.self) { zone in
                    zoneContent(zone)
                        .position(x: zone.courtPosition.x * geo.size.width,
                                  y: zone.courtPosition.y * geo.size.height)
                }
            }
        }
        .aspectRatio(CourtGeometry.w / CourtGeometry.h, contentMode: .fit)
    }
}

/// Just the rim circle, so it can be tinted with the brand color.
struct HalfCourtRim: Shape {
    func path(in rect: CGRect) -> Path {
        let g = CourtGeometry.self
        let center = CGPoint(x: g.cx / g.w * rect.width + rect.minX,
                             y: g.basketY / g.h * rect.height + rect.minY)
        let r = 16 / g.w * rect.width
        return Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                      width: r * 2, height: r * 2))
    }
}
