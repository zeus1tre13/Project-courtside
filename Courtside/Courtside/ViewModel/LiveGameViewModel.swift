import Foundation
import SwiftUI
import SwiftData
import Observation

/// Live-game entry state for the Direction B "player-first" scorer.
/// Both orderings are first-class: tap a player then a stat, or arm a stat
/// from the chip rail then tap the scorer. There is no "active team" — the
/// opponent is scored directly through the pinned quick-score bar.
enum LiveEntry: Equatable {
    case idle
    case playerArmed(UUID)            // player tapped — the stat sheet is open
    case statArmed(StatType)          // chip armed — waiting for a floor tap
    case zonePicker(StatType, UUID)   // stat + player chosen — needs a shot zone
}

@Observable
final class LiveGameViewModel {
    let game: Game
    let modelContext: ModelContext

    var entry: LiveEntry = .idle
    var activeLineup: [Player] = []
    var benchPlayers: [Player] = []
    var opponentPlayers: [Player] = []

    var showingSubstitution = false
    var showingBoxScore = false
    var showingEndGameConfirm = false
    var showingAddOpponent = false
    var showingPeriodTransition = false
    var pendingPeriod: Int?
    var showingAssistPrompt = false
    var assistPromptScorer: Player?

    /// All non-deleted events for this game, kept fresh so per-player stat
    /// lines and the recent-plays card update reactively after every commit.
    private(set) var events: [StatEvent] = []

    // Undo
    private(set) var undoStack: [StatEvent] = []
    var showUndoBanner = false
    var lastUndoableEvent: StatEvent?

    private var cachedMyTeamName: String?

    // MARK: - Init

    init(game: Game, modelContext: ModelContext) {
        self.game = game
        self.modelContext = modelContext
        setupInitialLineup()
        refreshEvents()
    }

    private func setupInitialLineup() {
        guard let teamID = game.myTeamID else { return }
        let predicate = #Predicate<Player> { $0.teamID == teamID && $0.isActive }
        let descriptor = FetchDescriptor<Player>(predicate: predicate)
        guard let players = try? modelContext.fetch(descriptor) else { return }

        if players.count >= 5 {
            activeLineup = Array(players.prefix(5))
            benchPlayers = Array(players.dropFirst(5))
        } else {
            activeLineup = players
            benchPlayers = []
        }

        if game.opponentTrackingLevel == .individual,
           let oppTeamID = game.opponentTeamID {
            let oppPredicate = #Predicate<Player> { $0.teamID == oppTeamID }
            let oppDescriptor = FetchDescriptor<Player>(predicate: oppPredicate)
            opponentPlayers = (try? modelContext.fetch(oppDescriptor)) ?? []
        }
    }

    // MARK: - Derived state

    var isIdle: Bool { entry == .idle }

    var armedPlayer: Player? {
        if case .playerArmed(let id) = entry { return player(id) }
        return nil
    }

    var armedStat: StatType? {
        if case .statArmed(let stat) = entry { return stat }
        return nil
    }

    /// The stat + player awaiting a shot-zone selection, if any.
    var pendingZone: (stat: StatType, player: Player)? {
        if case .zonePicker(let stat, let id) = entry, let p = player(id) {
            return (stat, p)
        }
        return nil
    }

    func player(_ id: UUID) -> Player? {
        activeLineup.first { $0.id == id }
            ?? benchPlayers.first { $0.id == id }
            ?? opponentPlayers.first { $0.id == id }
    }

    // MARK: - Scores & labels

    var myTeamScore: Int { game.myTeamScore }
    var opponentScore: Int { game.opponentScore }
    var periodLabel: String { game.periodLabel }
    var opponentName: String { game.opponentName }

    var myTeamName: String {
        if let cachedMyTeamName { return cachedMyTeamName }
        guard let teamID = game.myTeamID else { return "My Team" }
        let predicate = #Predicate<Team> { $0.id == teamID }
        let descriptor = FetchDescriptor<Team>(predicate: predicate)
        let name = (try? modelContext.fetch(descriptor).first)?.displayName ?? "My Team"
        cachedMyTeamName = name
        return name
    }

    // MARK: - Per-player stats

    func line(for player: Player) -> BoxScoreLine {
        StatCalculator.boxScoreLine(for: player, from: events)
    }

    /// FG line for a player's floor row, e.g. "3/7".
    func fgLine(for player: Player) -> String {
        let l = line(for: player)
        return "\(l.fieldGoalsMade)/\(l.fieldGoalsAttempted)"
    }

    // MARK: - Recent plays

    /// The three most recent events, newest first.
    var recentEvents: [StatEvent] {
        Array(events.suffix(3).reversed())
    }

    func displayName(for event: StatEvent) -> String {
        if let pid = event.playerID, let p = player(pid) {
            return "#\(p.jerseyNumber) \(p.lastName)"
        }
        return event.isOpponentStat ? opponentName : myTeamName
    }

    func description(for event: StatEvent) -> String {
        var base: String
        switch event.statType {
        case .fieldGoalMade:      base = "2PT made"
        case .fieldGoalMissed:    base = "2PT miss"
        case .threePointMade:     base = "3PT made"
        case .threePointMissed:   base = "3PT miss"
        case .freeThrowMade:      base = "FT made"
        case .freeThrowMissed:    base = "FT miss"
        case .offensiveRebound:   base = "Off. rebound"
        case .defensiveRebound:   base = "Rebound"
        case .assist:             base = "Assist"
        case .turnover:           base = "Turnover"
        case .steal:              base = "Steal"
        case .block:              base = "Block"
        case .foul:               base = "Foul"
        }
        if let zone = event.shotZone {
            base += " · \(zone.shortLabel)"
        }
        return base
    }

    // MARK: - Stat entry

    /// Player-first: tap a floor player. Tapping the armed player again
    /// deselects; tapping while a stat is armed completes the stat-first path.
    func armPlayer(_ player: Player) {
        switch entry {
        case .playerArmed(let id) where id == player.id:
            entry = .idle
        case .statArmed(let stat):
            attribute(stat: stat, to: player)
        default:
            entry = .playerArmed(player.id)
        }
        HapticManager.selectionChanged()
    }

    /// Stat-first: arm a chip. Tapping it again disarms; tapping while a
    /// player is armed completes the player-first path.
    func armStat(_ stat: StatType) {
        switch entry {
        case .statArmed(let current) where current == stat:
            entry = .idle
        case .playerArmed(let id):
            if let p = player(id) { attribute(stat: stat, to: p) }
        default:
            entry = .statArmed(stat)
        }
        HapticManager.selectionChanged()
    }

    /// A stat picked from the open player sheet.
    func recordStat(_ stat: StatType, for player: Player) {
        attribute(stat: stat, to: player)
    }

    private func attribute(stat: StatType, to player: Player) {
        if stat.requiresShotZone && game.trackShotZones {
            entry = .zonePicker(stat, player.id)
        } else {
            commit(stat: stat, zone: nil, player: player, isOpponent: false)
        }
    }

    func selectZone(_ zone: ShotZone) {
        guard case .zonePicker(let stat, let id) = entry, let p = player(id) else { return }
        commit(stat: stat, zone: zone, player: p, isOpponent: false)
    }

    /// Commit the pending shot without a zone — fast-play escape hatch.
    func skipZone() {
        guard case .zonePicker(let stat, let id) = entry, let p = player(id) else { return }
        commit(stat: stat, zone: nil, player: p, isOpponent: false)
    }

    func cancelEntry() {
        entry = .idle
    }

    /// Opponent quick-score from the pinned bar — always team-level, never
    /// armed, never a zone. Returns the committed event for the toast.
    func recordOpponentQuick(_ stat: StatType) {
        commit(stat: stat, zone: nil, player: nil, isOpponent: true)
    }

    // MARK: - Commit / undo

    private func commit(stat: StatType, zone: ShotZone?, player: Player?, isOpponent: Bool) {
        let event = StatEvent(
            statType: stat,
            isOpponentStat: isOpponent,
            shotZone: zone,
            period: game.currentPeriod,
            sequenceNumber: game.nextSequenceNumber,
            playerID: player?.id
        )
        event.gameID = game.id
        modelContext.insert(event)

        undoStack.append(event)
        if undoStack.count > Constants.maxUndoStackSize {
            undoStack.removeFirst()
        }
        lastUndoableEvent = event
        showUndoBanner = true

        entry = .idle
        refreshEvents()
        HapticManager.statRecorded()

        // After a made 2PT/3PT by one of my players, ask who assisted.
        if !isOpponent, let player,
           stat == .fieldGoalMade || stat == .threePointMade,
           game.promptForAssists {
            assistPromptScorer = player
            showingAssistPrompt = true
        }
    }

    /// Teammates eligible to be credited with an assist on the pending shot.
    var assistCandidates: [Player] {
        guard let scorer = assistPromptScorer else { return [] }
        return activeLineup.filter { $0.id != scorer.id }
    }

    func recordAssist(by teammate: Player) {
        showingAssistPrompt = false
        assistPromptScorer = nil
        commit(stat: .assist, zone: nil, player: teammate, isOpponent: false)
    }

    func dismissAssistPrompt() {
        showingAssistPrompt = false
        assistPromptScorer = nil
    }

    func undoLastStat() {
        guard let last = undoStack.popLast() else { return }
        last.isDeleted = true
        lastUndoableEvent = undoStack.last
        showUndoBanner = false
        refreshEvents()
        HapticManager.undoPerformed()
    }

    private func refreshEvents() {
        let gameID = game.id
        let predicate = #Predicate<StatEvent> { $0.gameID == gameID && !$0.isDeleted }
        var descriptor = FetchDescriptor<StatEvent>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.sequenceNumber)]
        events = (try? modelContext.fetch(descriptor)) ?? []
        syncScores()
    }

    private func syncScores() {
        game.myTeamScore = events
            .filter { !$0.isOpponentStat }
            .reduce(0) { $0 + $1.statType.pointValue }
        game.opponentScore = events
            .filter { $0.isOpponentStat }
            .reduce(0) { $0 + $1.statType.pointValue }
    }

    // MARK: - Substitution

    func substitute(playerOut: Player, playerIn: Player) {
        guard let outIndex = activeLineup.firstIndex(where: { $0.id == playerOut.id }),
              let inIndex = benchPlayers.firstIndex(where: { $0.id == playerIn.id }) else { return }

        let change = LineupChange(
            period: game.currentPeriod,
            sequenceNumber: game.nextSequenceNumber,
            playerInID: playerIn.id,
            playerOutID: playerOut.id
        )
        change.gameID = game.id
        modelContext.insert(change)

        activeLineup[outIndex] = playerIn
        benchPlayers[inIndex] = playerOut

        HapticManager.selectionChanged()
    }

    // MARK: - Add opponent player (during game)

    func addOpponentPlayer(firstName: String, lastName: String, jerseyNumber: String) {
        guard let oppTeamID = game.opponentTeamID else { return }
        let player = Player(
            firstName: firstName,
            lastName: lastName,
            jerseyNumber: jerseyNumber
        )
        player.teamID = oppTeamID
        modelContext.insert(player)
        opponentPlayers.append(player)
    }

    // MARK: - Period

    func setPeriod(_ period: Int) {
        guard period >= 1, period != game.currentPeriod else { return }
        game.currentPeriod = period
        HapticManager.periodAdvanced()
    }

    /// Advancing to the next period asks for confirmation; jumping to any
    /// other period (a correction) applies directly.
    func requestPeriod(_ period: Int) {
        if period == game.currentPeriod + 1 {
            pendingPeriod = period
            showingPeriodTransition = true
        } else {
            setPeriod(period)
        }
    }

    func confirmPeriodAdvance() {
        if let period = pendingPeriod { setPeriod(period) }
        pendingPeriod = nil
        showingPeriodTransition = false
    }

    func cancelPeriodAdvance() {
        pendingPeriod = nil
        showingPeriodTransition = false
    }

    /// Points scored in a period by one side.
    func periodPoints(_ period: Int, isOpponent: Bool) -> Int {
        events
            .filter { $0.period == period && $0.isOpponentStat == isOpponent }
            .reduce(0) { $0 + $1.statType.pointValue }
    }

    /// My players carrying 3+ fouls — the foul-trouble heads-up.
    func foulTrouble() -> [(player: Player, fouls: Int)] {
        (activeLineup + benchPlayers).compactMap { player in
            let fouls = line(for: player).fouls
            return fouls >= 3 ? (player, fouls) : nil
        }
    }

    /// Highest-scoring player on my team within a single period.
    func topScorer(inPeriod period: Int) -> (player: Player, points: Int)? {
        var best: (player: Player, points: Int)?
        for player in activeLineup + benchPlayers {
            let points = events
                .filter { $0.playerID == player.id && $0.period == period && !$0.isOpponentStat }
                .reduce(0) { $0 + $1.statType.pointValue }
            if points > 0, points > (best?.points ?? 0) {
                best = (player, points)
            }
        }
        return best
    }

    // MARK: - End game

    func endGame() {
        game.isComplete = true
    }
}
