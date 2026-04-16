import SwiftUI

// MARK: - Chart mode

enum ChartMode: String, CaseIterable, Hashable {
    case team     = "Our Team"
    case opponent = "Opponent"
    case player   = "Player"
}

// MARK: - Main display view

/// Read-only half-court visualization.
///
/// Renders each ShotZone as a colored overlay with a percentage (or count) label.
/// Tapping a zone opens a ZoneShotListView sheet listing individual shots.
///
/// - Parameters:
///   - data:      The shot data to display (team, opponent, or player-filtered).
///   - mode:      Determines the coloring scheme.
///   - teamData:  Full team data — used in `.player` mode to compare against team average.
///   - players:   Player lookup array for the drill-down list.
struct ShotCourtDisplayView: View {
    let data: ShotChartData
    let mode: ChartMode
    let teamData: ShotChartData
    let players: [Player]

    @State private var tappedZone: ShotZone?

    var body: some View {
        VStack(spacing: 0) {
            if data.isEmpty {
                emptyState
            } else {
                courtView
                ftRow
            }
        }
        .sheet(item: $tappedZone) { zone in
            ZoneShotListView(
                zone: zone,
                events: data.events(for: zone),
                players: players
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Court

    private var courtView: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * 0.85

            ZStack {
                CourtFill()
                    .fill(Color(.systemGray6))
                    .frame(width: width, height: height)

                CourtShape()
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1.5)
                    .frame(width: width, height: height)

                ForEach(ShotZone.allCases, id: \.self) { zone in
                    let rect = zone.hitArea
                    let zoneRect = CGRect(
                        x: rect.origin.x * width,
                        y: rect.origin.y * height,
                        width: rect.width * width,
                        height: rect.height * height
                    )
                    ZoneOverlay(
                        zone: zone,
                        stat: data.zoneStats[zone],
                        mode: mode,
                        teamStat: teamData.zoneStats[zone],
                        maxAttempts: data.maxZoneAttempts,
                        rect: zoneRect
                    ) {
                        if data.zoneStats[zone] != nil {
                            tappedZone = zone
                        }
                    }
                }
            }
            .frame(width: width, height: height)
        }
        .aspectRatio(1 / 0.85, contentMode: .fit)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * 0.85

            ZStack {
                CourtFill()
                    .fill(Color(.systemGray6))
                    .frame(width: width, height: height)

                CourtShape()
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                    .frame(width: width, height: height)

                VStack(spacing: 8) {
                    Image(systemName: "basketball")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No shots recorded")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .position(x: width / 2, y: height * 0.45)
            }
            .frame(width: width, height: height)
        }
        .aspectRatio(1 / 0.85, contentMode: .fit)
    }

    // MARK: - FT row

    @ViewBuilder
    private var ftRow: some View {
        if data.ftAttempted > 0 {
            HStack {
                Text("Free Throws")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let made = data.ftMade
                let att  = data.ftAttempted
                Text("\(made)/\(att)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                if let pct = data.ftPercentage {
                    Text("(\(Int(round(pct * 100)))%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
    }
}

// MARK: - Zone overlay

private struct ZoneOverlay: View {
    let zone: ShotZone
    let stat: ShotZoneStat?
    let mode: ChartMode
    let teamStat: ShotZoneStat?
    let maxAttempts: Int
    let rect: CGRect
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(fillColor)
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(borderColor, lineWidth: 1)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(labelColor)
                    .padding(2)
            }
            .frame(width: rect.width, height: rect.height)
        }
        .buttonStyle(.plain)
        .position(x: rect.midX, y: rect.midY)
        .disabled(stat == nil)
    }

    // MARK: - Color logic

    private var fillColor: Color {
        guard let stat, stat.attempted > 0 else {
            return Color.clear
        }
        guard stat.hasEnoughAttempts else {
            return Color(.systemGray4).opacity(0.45)
        }

        switch mode {
        case .team:
            // Volume: opacity scales from 15% (1 attempt) to 70% (max attempts)
            let intensity = Double(stat.attempted) / Double(max(maxAttempts, 1))
            return Color.blue.opacity(0.15 + intensity * 0.55)

        case .opponent:
            guard let pct = stat.percentage else { return Color(.systemGray4).opacity(0.4) }
            if pct < 0.30 { return Color.blue.opacity(0.45) }
            if pct < 0.45 { return Color(.systemGray4).opacity(0.4) }
            return Color.red.opacity(0.50)

        case .player:
            guard let playerPct = stat.percentage else { return Color(.systemGray4).opacity(0.4) }
            // Compare against team average; if team has <3 attempts in zone, show neutral
            guard let tStat = teamStat,
                  tStat.hasEnoughAttempts,
                  let teamPct = tStat.percentage else {
                return Color(.systemGray4).opacity(0.4)
            }
            let diff = playerPct - teamPct
            if diff > 0.08  { return Color.red.opacity(0.50) }
            if diff < -0.08 { return Color.blue.opacity(0.45) }
            return Color(.systemGray4).opacity(0.4)
        }
    }

    private var borderColor: Color {
        guard let stat, stat.attempted > 0 else {
            return Color.primary.opacity(0.08)
        }
        return fillColor.opacity(0.6)
    }

    private var labelColor: Color {
        guard let stat, stat.attempted > 0 else {
            return Color.primary.opacity(0.3)
        }
        return Color.primary.opacity(0.85)
    }

    // MARK: - Label logic

    private var label: String {
        guard let stat, stat.attempted > 0 else {
            return zone.shortLabel
        }
        if !stat.hasEnoughAttempts {
            // Show raw count when too few attempts for a meaningful percentage
            return "\(stat.attempted)"
        }
        let pct = Int(round((stat.percentage ?? 0) * 100))
        return "\(pct)%"
    }
}

// MARK: - ShotZone: sheet item conformance

extension ShotZone: Identifiable {
    public var id: String { rawValue }
}
