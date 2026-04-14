import SwiftUI
import SwiftData

// MARK: - Cell Category

/// Which box score cell the edit sheet was opened from.
/// Drives both event filtering (what the list shows) and
/// the default stat picker for the Add flow.
enum BoxScoreCell: Equatable {
    case allStats
    case points
    case fieldGoals
    case threePoints
    case freeThrows
    case rebounds
    case assists
    case turnovers
    case steals
    case blocks
    case fouls

    var title: String {
        switch self {
        case .allStats:    return "All Stats"
        case .points:      return "PTS"
        case .fieldGoals:  return "FG"
        case .threePoints: return "3PT"
        case .freeThrows:  return "FT"
        case .rebounds:    return "REB"
        case .assists:     return "AST"
        case .turnovers:   return "TO"
        case .steals:      return "STL"
        case .blocks:      return "BLK"
        case .fouls:       return "PF"
        }
    }

    /// StatTypes included in this cell.
    var statTypes: [StatType] {
        switch self {
        case .allStats:    return StatType.allCases
        case .points:      return [.fieldGoalMade, .threePointMade, .freeThrowMade]
        case .fieldGoals:  return [.fieldGoalMade, .fieldGoalMissed, .threePointMade, .threePointMissed]
        case .threePoints: return [.threePointMade, .threePointMissed]
        case .freeThrows:  return [.freeThrowMade, .freeThrowMissed]
        case .rebounds:    return [.offensiveRebound, .defensiveRebound]
        case .assists:     return [.assist]
        case .turnovers:   return [.turnover]
        case .steals:      return [.steal]
        case .blocks:      return [.block]
        case .fouls:       return [.foul]
        }
    }
}

// MARK: - Edit Sheet

/// Sheet shown when a box score cell is tapped.
/// Lists the StatEvents behind that number (delete via swipe)
/// and offers an Add flow scoped to the cell category.
struct BoxScoreEditSheet: View {
    let game: Game
    /// nil = totals row (team-level)
    let player: Player?
    let cell: BoxScoreCell
    let isOpponent: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allEvents: [StatEvent]

    @State private var showAddForm = false

    private var events: [StatEvent] {
        let types = Set(cell.statTypes.map { $0.rawValue })
        let gameID = game.id
        let playerID = player?.id
        return allEvents
            .filter {
                $0.gameID == gameID &&
                $0.isOpponentStat == isOpponent &&
                !$0.isDeleted &&
                types.contains($0.statTypeRaw) &&
                (playerID == nil || $0.playerID == playerID)
            }
            .sorted {
                if $0.period != $1.period { return $0.period < $1.period }
                return $0.sequenceNumber < $1.sequenceNumber
            }
    }

    private var subjectLabel: String {
        if let player = player {
            return "#\(player.jerseyNumber) \(player.shortName)"
        }
        return isOpponent ? game.opponentName : "Team Total"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if events.isEmpty {
                        Text("No events logged")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(events) { event in
                            eventRow(event)
                        }
                        .onDelete(perform: deleteEvents)
                    }
                } header: {
                    Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                }

                Section {
                    Button {
                        showAddForm = true
                    } label: {
                        Label("Add Event", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("\(subjectLabel) · \(cell.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddForm) {
                AddStatEventForm(
                    game: game,
                    player: player,
                    cell: cell,
                    isOpponent: isOpponent
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func eventRow(_ event: StatEvent) -> some View {
        HStack {
            Text(game.format.periodLabel(for: event.period))
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.statType.displayName)
                    .font(.body)
                if let zone = event.shotZone {
                    Text(zone.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(event.timestamp, format: .dateTime.hour().minute())
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func deleteEvents(at offsets: IndexSet) {
        for idx in offsets {
            let event = events[idx]
            softDelete(event)
        }
    }

    private func softDelete(_ event: StatEvent) {
        guard !event.isDeleted else { return }
        let points = event.statType.pointValue
        if points > 0 {
            if event.isOpponentStat {
                game.opponentScore = max(0, game.opponentScore - points)
            } else {
                game.myTeamScore = max(0, game.myTeamScore - points)
            }
        }
        event.isDeleted = true
        HapticManager.undoPerformed()
    }
}

// MARK: - Add Event Form

/// Mini form for creating a StatEvent after-the-fact.
/// Scoped by `cell`: if cell is a specific stat (e.g., .threePoints),
/// only that cell's StatTypes are offered. For .allStats, the full
/// list is shown.
struct AddStatEventForm: View {
    let game: Game
    let player: Player?
    let cell: BoxScoreCell
    let isOpponent: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStatType: StatType
    @State private var selectedZone: ShotZone?
    @State private var selectedPeriod: Int

    init(game: Game, player: Player?, cell: BoxScoreCell, isOpponent: Bool) {
        self.game = game
        self.player = player
        self.cell = cell
        self.isOpponent = isOpponent
        _selectedStatType = State(initialValue: cell.statTypes.first ?? .fieldGoalMade)
        _selectedZone = State(initialValue: nil)
        _selectedPeriod = State(initialValue: game.currentPeriod)
    }

    private var availableStatTypes: [StatType] {
        cell.statTypes
    }

    private var needsZone: Bool {
        game.trackShotZones && selectedStatType.requiresShotZone
    }

    private var canSave: Bool {
        if needsZone { return selectedZone != nil }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Stat") {
                    if availableStatTypes.count == 1 {
                        HStack {
                            Text(selectedStatType.displayName)
                            Spacer()
                        }
                    } else {
                        Picker("Stat", selection: $selectedStatType) {
                            ForEach(availableStatTypes, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }

                Section("Period") {
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(1...max(game.currentPeriod, game.format.periodCount), id: \.self) { p in
                            Text(game.format.periodLabel(for: p)).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if needsZone {
                    Section("Shot Zone") {
                        Picker("Zone", selection: $selectedZone) {
                            Text("Select…").tag(Optional<ShotZone>.none)
                            ForEach(selectedStatType.validShotZones, id: \.self) { z in
                                Text(z.displayName).tag(Optional(z))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedStatType) { _, _ in
                // Reset zone when stat type changes — different stats use different zone sets
                selectedZone = nil
            }
        }
    }

    private func save() {
        let event = StatEvent(
            statType: selectedStatType,
            isOpponentStat: isOpponent,
            shotZone: needsZone ? selectedZone : nil,
            period: selectedPeriod,
            sequenceNumber: game.nextSequenceNumber,
            playerID: player?.id
        )
        event.gameID = game.id
        modelContext.insert(event)

        let points = selectedStatType.pointValue
        if points > 0 {
            if isOpponent {
                game.opponentScore += points
            } else {
                game.myTeamScore += points
            }
        }

        HapticManager.statRecorded()
        dismiss()
    }
}
