import SwiftUI

// ---------------------------------------------------------------------------
// Shot-chart heat map — the 12 zones from the live picker, tinted by FG%.
// ShotHeatCourt is the bare court (reused by the recap preview); ShotHeatMapView
// is the full post-game tab with the player filter, legend, and zone list.
// ---------------------------------------------------------------------------

/// FG%-tinted heat color for a zone.
private func heatStyle(_ stat: ShotZoneStat?) -> (bg: Color, border: Color, ink: Color) {
    guard let stat, stat.attempted > 0, let pct = stat.percentage else {
        return (CS.bgStage, CS.lineStrong, CS.inkDim)
    }
    switch pct {
    case 0.60...:    return (CS.made.opacity(0.55), CS.made, CS.ink)
    case 0.40..<0.60: return (CS.made.opacity(0.25), CS.made.opacity(0.6), CS.ink)
    case 0.25..<0.40: return (CS.missInk.opacity(0.12), CS.missInk.opacity(0.35), CS.inkMute)
    default:          return (CS.missInk.opacity(0.22), CS.missInk.opacity(0.55), CS.inkMute)
    }
}

/// A single heat chip — made/attempted and percent, tinted by FG%.
private struct HeatChip: View {
    let stat: ShotZoneStat?
    var compact: Bool = false

    var body: some View {
        let style = heatStyle(stat)
        let made = stat?.made ?? 0
        let att = stat?.attempted ?? 0
        VStack(spacing: 1) {
            Text("\(made)/\(att)")
                .font(.csMono(compact ? 9 : 11, weight: .bold))
                .foregroundStyle(style.ink)
            if !compact {
                Text(stat?.percentage != nil
                     ? "\(Int(((stat?.percentage) ?? 0) * 100))%"
                     : "—")
                    .font(.csUI(9, weight: .semibold))
                    .foregroundStyle(CS.inkDim)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 5)
        .frame(minWidth: compact ? 34 : 46)
        .background {
            Color.white
            style.bg
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style.border, lineWidth: 1.4)
        )
    }
}

/// The bare heat-map court — court geometry + a heat chip per zone.
struct ShotHeatCourt: View {
    let data: ShotChartData
    var compact: Bool = false

    var body: some View {
        HalfCourtChart { zone in
            HeatChip(stat: data.zoneStats[zone], compact: compact)
        }
    }
}

/// Full post-game shot-chart tab.
struct ShotHeatMapView: View {
    let events: [StatEvent]
    let myPlayers: [Player]

    @State private var selectedPlayerID: UUID?

    private var data: ShotChartData {
        ShotChartCalculator.compute(from: events, isOpponent: false, playerID: selectedPlayerID)
    }

    private var shooters: [Player] {
        myPlayers.filter { player in
            !ShotChartCalculator
                .compute(from: events, isOpponent: false, playerID: player.id)
                .isEmpty
        }
    }

    /// Zones with attempts, sorted best FG% first.
    private var rankedZones: [(zone: ShotZone, stat: ShotZoneStat)] {
        data.zoneStats
            .map { ($0.key, $0.value) }
            .sorted { ($0.1.percentage ?? -1) > ($1.1.percentage ?? -1) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                playerFilter

                courtCard

                if !rankedZones.isEmpty {
                    zoneBreakdown
                }
            }
            .padding(.vertical, 12)
        }
        .background(CS.bgStage)
    }

    // MARK: - Player filter

    private var playerFilter: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                filterPill(label: "Team", jersey: nil,
                           selected: selectedPlayerID == nil) {
                    selectedPlayerID = nil
                }
                ForEach(shooters, id: \.id) { player in
                    filterPill(label: player.firstName.isEmpty ? player.lastName : player.firstName,
                               jersey: player.jerseyNumber,
                               selected: selectedPlayerID == player.id) {
                        selectedPlayerID = player.id
                    }
                }
            }
            .padding(.horizontal, 14)
        }
        .scrollIndicators(.hidden)
    }

    private func filterPill(label: String, jersey: String?,
                            selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let jersey {
                    Jersey(number: jersey, color: CS.home, size: 20)
                }
                Text(label)
            }
            .font(.csUI(12, weight: .bold))
            .foregroundStyle(selected ? .white : CS.inkMute)
            .padding(.horizontal, jersey == nil ? 12 : 6)
            .padding(.vertical, 5)
            .padding(.trailing, jersey == nil ? 0 : 6)
            .background(selected ? CS.ink : CS.bgSoft, in: Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Court card

    private var courtCard: some View {
        VStack(spacing: 8) {
            if data.isEmpty {
                Text("No shots with a recorded zone yet.")
                    .font(.csUI(13))
                    .foregroundStyle(CS.inkMute)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ShotHeatCourt(data: data)
                legend
            }
        }
        .padding(10)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1))
        .padding(.horizontal, 14)
    }

    private var legend: some View {
        HStack {
            HStack(spacing: 5) {
                Text("FG%")
                    .font(.csUI(9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(CS.inkDim)
                HStack(spacing: 0) {
                    ForEach(Array(rampColors.enumerated()), id: \.offset) { _, color in
                        Rectangle().fill(color).frame(width: 20, height: 10)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(CS.line, lineWidth: 1))
                Text("0 · 50 · 100")
                    .font(.csMono(9))
                    .foregroundStyle(CS.inkDim)
            }
            Spacer()
        }
    }

    private var rampColors: [Color] {
        [
            CS.missInk.opacity(0.22),
            CS.missInk.opacity(0.12),
            CS.bgStage,
            CS.made.opacity(0.25),
            CS.made.opacity(0.45),
            CS.made.opacity(0.7),
        ]
    }

    // MARK: - Zone breakdown

    private var zoneBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BEST AND WORST ZONES")
                .font(.csUI(11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(CS.inkDim)
                .padding(.horizontal, 14)

            VStack(spacing: 6) {
                ForEach(Array(rankedZones.enumerated()), id: \.offset) { index, entry in
                    zoneRow(zone: entry.zone, stat: entry.stat,
                            isBest: index == 0,
                            isWorst: index == rankedZones.count - 1 && rankedZones.count > 1)
                }
            }
            .padding(.horizontal, 14)
        }
    }

    private func zoneRow(zone: ShotZone, stat: ShotZoneStat,
                         isBest: Bool, isWorst: Bool) -> some View {
        let pct = Int((stat.percentage ?? 0) * 100)
        let barColor: Color = pct >= 50 ? CS.made : pct >= 30 ? CS.amber : CS.missInk.opacity(0.6)
        return HStack(spacing: 12) {
            Circle()
                .fill(zone.isThreePointZone ? CS.away : CS.amber)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(zone.displayName)
                    .font(.csUI(13, weight: .bold))
                    .foregroundStyle(CS.ink)
                Text("\(stat.made)/\(stat.attempted) attempts")
                    .font(.csMono(11))
                    .foregroundStyle(CS.inkMute)
            }

            Spacer(minLength: 0)

            ZStack(alignment: .leading) {
                Capsule().fill(CS.bgSoft).frame(width: 64, height: 5)
                Capsule().fill(barColor)
                    .frame(width: 64 * CGFloat(min(pct, 100)) / 100, height: 5)
            }

            HStack(spacing: 5) {
                Text("\(pct)%")
                    .font(.csDisplay(20, weight: .heavy))
                    .foregroundStyle(pct >= 50 ? CS.made : pct >= 30 ? CS.ink : CS.missInk)
                if isBest {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(CS.brand)
                } else if isWorst {
                    Image(systemName: "snowflake")
                        .font(.system(size: 12))
                        .foregroundStyle(CS.inkDim)
                }
            }
            .frame(width: 64, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CS.line, lineWidth: 1))
    }
}
