import SwiftUI

/// Shared component that combines the mode picker, optional player picker,
/// and the court visualization. Used in both GameSummaryView and TeamAnalyticsView.
///
/// - Parameters:
///   - events:            Pre-filtered StatEvents for the current scope.
///   - myPlayers:         Players on the tracked team.
///   - opponentPlayers:   Players on the opponent (may be empty if not individually tracked).
struct ShotChartSectionView: View {
    let events: [StatEvent]
    let myPlayers: [Player]
    let opponentPlayers: [Player]

    @State private var mode: ChartMode = .team
    @State private var selectedPlayerID: UUID?

    // MARK: - Aggregated data

    private var teamData: ShotChartData {
        ShotChartCalculator.compute(from: events, isOpponent: false)
    }

    private var opponentData: ShotChartData {
        ShotChartCalculator.compute(from: events, isOpponent: true)
    }

    private func playerData(for id: UUID) -> ShotChartData {
        ShotChartCalculator.compute(from: events, isOpponent: false, playerID: id)
    }

    private var displayData: ShotChartData {
        switch mode {
        case .team:     return teamData
        case .opponent: return opponentData
        case .player:
            guard let id = resolvedPlayerID else { return teamData }
            return playerData(for: id)
        }
    }

    /// In player mode, default to the first player (by jersey number) if none selected.
    private var resolvedPlayerID: UUID? {
        if let id = selectedPlayerID, sortedMyPlayers.contains(where: { $0.id == id }) {
            return id
        }
        return sortedMyPlayers.first?.id
    }

    private var sortedMyPlayers: [Player] {
        myPlayers.sorted { (Int($0.jerseyNumber) ?? 999) < (Int($1.jerseyNumber) ?? 999) }
    }

    // Players shown in the drill-down depend on mode
    private var drillDownPlayers: [Player] {
        mode == .opponent ? opponentPlayers : myPlayers
    }

    var body: some View {
        VStack(spacing: 16) {
            // Mode picker
            Picker("Mode", selection: $mode) {
                ForEach(pickerModes, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _, newMode in
                // Reset player selection when switching modes
                if newMode != .player { selectedPlayerID = nil }
            }

            // Player picker (individual mode only)
            if mode == .player && !sortedMyPlayers.isEmpty {
                Picker("Player", selection: $selectedPlayerID) {
                    ForEach(sortedMyPlayers) { player in
                        Text(player.displayLabel)
                            .tag(Optional<UUID>.some(player.id))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Court visualization
            ShotCourtDisplayView(
                data: displayData,
                mode: mode,
                teamData: teamData,
                players: drillDownPlayers
            )
        }
    }

    /// Only show Opponent tab if opponent players exist (individual tracking on)
    /// or if there are any opponent events with zones recorded.
    private var pickerModes: [ChartMode] {
        let hasOpponent = !opponentPlayers.isEmpty ||
            events.contains { $0.isOpponentStat && $0.shotZone != nil && !$0.isDeleted }
        return hasOpponent ? ChartMode.allCases : [.team, .player]
    }
}
