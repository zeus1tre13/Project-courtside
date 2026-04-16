import SwiftUI

/// Decorative full-court basketball diagram rendered via Canvas.
/// Used as a low-opacity background behind the Home header.
struct CourtDiagramView: View {
    var strokeColor: Color = Color(hex: "#FF5E1A")
    var lineWidth: CGFloat = 1.2

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            let dashed = StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .butt,
                lineJoin: .round,
                dash: [3, 3]
            )
            let shading = GraphicsContext.Shading.color(strokeColor)

            // Outer boundary
            context.stroke(
                Path(CGRect(x: 0, y: 0, width: w, height: h)),
                with: shading,
                style: stroke
            )

            // Half-court line
            var halfLine = Path()
            halfLine.move(to: CGPoint(x: w / 2, y: 0))
            halfLine.addLine(to: CGPoint(x: w / 2, y: h))
            context.stroke(halfLine, with: shading, style: stroke)

            // Center circle
            let centerR = h * 0.12
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: w / 2 - centerR, y: h / 2 - centerR,
                    width: centerR * 2, height: centerR * 2
                )),
                with: shading,
                style: stroke
            )

            // Center dot
            let dotR: CGFloat = 2
            context.fill(
                Path(ellipseIn: CGRect(
                    x: w / 2 - dotR, y: h / 2 - dotR,
                    width: dotR * 2, height: dotR * 2
                )),
                with: shading
            )

            // Three-second lanes (outer key)
            let laneDepth = w * 0.17
            let laneWidth = h * 0.42
            let laneY = h / 2 - laneWidth / 2
            context.stroke(
                Path(CGRect(x: 0, y: laneY, width: laneDepth, height: laneWidth)),
                with: shading,
                style: stroke
            )
            context.stroke(
                Path(CGRect(x: w - laneDepth, y: laneY, width: laneDepth, height: laneWidth)),
                with: shading,
                style: stroke
            )

            // Paint boxes (inner painted area)
            let paintDepth = w * 0.135
            let paintWidth = h * 0.26
            let paintY = h / 2 - paintWidth / 2
            context.stroke(
                Path(CGRect(x: 0, y: paintY, width: paintDepth, height: paintWidth)),
                with: shading,
                style: stroke
            )
            context.stroke(
                Path(CGRect(x: w - paintDepth, y: paintY, width: paintDepth, height: paintWidth)),
                with: shading,
                style: stroke
            )

            // Free throw arcs (dashed semicircles)
            let ftR = h * 0.13
            var leftArc = Path()
            leftArc.addArc(
                center: CGPoint(x: laneDepth, y: h / 2),
                radius: ftR,
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                clockwise: false
            )
            context.stroke(leftArc, with: shading, style: dashed)

            var rightArc = Path()
            rightArc.addArc(
                center: CGPoint(x: w - laneDepth, y: h / 2),
                radius: ftR,
                startAngle: .degrees(90),
                endAngle: .degrees(270),
                clockwise: false
            )
            context.stroke(rightArc, with: shading, style: dashed)

            // Basket circles
            let basketR: CGFloat = 4
            let basketOffset = w * 0.045
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: basketOffset - basketR, y: h / 2 - basketR,
                    width: basketR * 2, height: basketR * 2
                )),
                with: shading,
                style: stroke
            )
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: w - basketOffset - basketR, y: h / 2 - basketR,
                    width: basketR * 2, height: basketR * 2
                )),
                with: shading,
                style: stroke
            )

            // Hash marks along sidelines
            let hashLen: CGFloat = 6
            for xPos in [w * 0.28, w * 0.72] {
                var top = Path()
                top.move(to: CGPoint(x: xPos, y: 0))
                top.addLine(to: CGPoint(x: xPos, y: hashLen))
                context.stroke(top, with: shading, style: stroke)

                var bot = Path()
                bot.move(to: CGPoint(x: xPos, y: h - hashLen))
                bot.addLine(to: CGPoint(x: xPos, y: h))
                context.stroke(bot, with: shading, style: stroke)
            }
        }
    }
}
