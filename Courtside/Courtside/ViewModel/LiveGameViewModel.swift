import Foundation
import SwiftData
import Observation

enum StatEntryState: Equatable {
    case idle
    case statSelected(StatType, isOpponent: Bool)
    case zoneSelected(StatType, ShotZone, isOpponent: Bool)

    static func == (lhs: StatEntryState, rhs: StatEntryState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.statSelected(lt, lo), .statSelected(rt, ro)):
            return lt == rt && lo == ro
        case let (.zoneSelected(lt, lz, lo), .zoneSelected(rt, rz, ro)):
            return lt == rt && lz == rz && lo == ro
        default:
            return false
        }
    }
}

@Observable
final class LiveGameViewModel {
    let game: Game
    let modelContext: ModelContext

    var entryState: StatEntryState = .idle
    var activeLineup: [Player] = []
    var benchPlayers: [Player] = []
    var opponentPlayers: [Player] = []
    var isTrackingOpponent: Bool = false
    var showingSubstitution: Bool = false
    var showingBoxScore: Bool = false
    var showingEndGameConfirm: Bool = false

    // Undo
    private(set) var undoStack: [StatEvent] = []
    var showUndoBanner: Bool = false
    var lastUndoableEvent: StatEvent?

    // Computed
    var isIdle: Bool {
        entryState == .idle
    }

    var currentStatType: StatType? {
        switch entryState {
        case .statSelected(let stat, _): return stat
        case .zoneSelected(let stat, _, _): return stat
        default: return nil
        }
    }

    var needsZoneSelection: Bool {
        guard game.trackShotZones else { return false }
        switch entryState {
        case .statSelected(let stat, _):
            return stat.requiresShotZone
        default:
            return false
        }
    }

    var needsPlayerSelection: Bool {
        switch entryState {
        case .statSelected(let stat, let isOpp):
            if isOpp && game.opponentTrackingLevel == .team { return false }
            // If shot needs zone and zones are tracked, wait for zone first
            if stat.requiresShotZone && game.trackShotZones { return false }
            return true
        case .zoneSelected(_, _, let isOpp):
            if isOpp && game.opponentTrackingLevel == .team { return false }
            return true
        default:
            return false
        }
    }

    var currentPlayers: [Player] {
        if isTrackingOpponent {
            return opponentPlayers
        }
        return activeLineup
    }

    var myTeamScore: Int { game.myTeamScore }
    var opponentScore: Int { game.opponentScore }
    var periodLabel: String { game.periodLabel }

    init(game: Game, modelContext: ModelContext) {
        self.game = game
        self.modelContext = modelContext
        setupInitialLineup()
    }

    // MARK: - Setup

    private func setupInitialLineup() {
        // My team players
        guard let teamID = game.myTeamID else { return }
        let predicate = #Predicate<Player> { $0.teamID == teamID && $0.isActive }
        let descriptor = FetchDescriptor<Player>(predicate: predicate)
        guard let players = try? modelContext.fetch(descriptor) else { return }

        // First 5 start, rest on bench
        if players.count >= 5 {
            activeLineup = Array(players.prefix(5))
            benchPlayers = Array(players.dropFirst(5))
        } else {
            activeLineup = players
            benchPlayers = []
        }

        // Opponent players (if tracking individually)
        if game.opponentTrackingLevel == .individual,
           let oppTeamID = game.opponentTeamID {
            let oppPredicate = #Predicate<Player> { $0.teamID == oppTeamID }
            let oppDescriptor = FetchDescriptor<Player>(predicate: oppPredicate)
            opponentPlayers = (try? modelContext.fetch(oppDescriptor)) ?? []
        }
    }

    // MARK: - Stat Entry (Stat-First Flow)

    func selectStat(_ stat: StatType) {
        let isOpp = isTrackingOpponent

        if stat.requiresShotZone {
            // Need zone next
            entryState = .statSelected(stat, isOpponent: isOpp)
        } else if stat.isFreeThrow {
            // Free throws: skip zone, go to player
            entryState = .statSelected(stat, isOpponent: isOpp)
            // If team-level opponent tracking, commit immediately
            if isOpp && game.opponentTrackingLevel == .team {
                commitStat(stat: stat, zone: nil, player: nil, isOpponent: true)
            }
        } else {
            // Non-shot stat: skip zone, go to player
            entryState = .statSelected(stat, isOpponent: isOpp)
            if isOpp && game.opponentTrackingLevel == .team {
                commitStat(stat: stat, zone: nil, player: nil, isOpponent: true)
            }
        }

        HapticManager.selectionChanged()
    }

    func selectZone(_ zone: ShotZone) {
        guard case .statSelected(let stat, let isOpp) = entryState else { return }

        if isOpp && game.opponentTrackingLevel == .team {
            commitStat(stat: stat, zone: zone, player: nil, isOpponent: true)
        } else {
            entryState = .zoneSelected(stat, zone, isOpponent: isOpp)
        }
    }

    func selectPlayer(_ player: Player) {
        switch entryState {
        case .statSelected(let stat, let isOpp):
            commitStat(stat: stat, zone: nil, player: player, isOpponent: isOpp)
        case .zoneSelected(let stat, let zone, let isOpp):
            commitStat(stat: stat, zone: zone, player: player, isOpponent: isOpp)
        default:
            break
        }
    }

    // MARK: - Commit

    private func commitStat(stat: StatType, zone: ShotZone?, player: Player?, isOpponent: Bool) {
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

        // Update score
        let points = stat.pointValue
        if points > 0 {
            if isOpponent {
                game.opponentScore += points
            } else {
                game.myTeamScore += points
            }
        }

        // Undo stack
        undoStack.append(event)
        if undoStack.count > Constants.maxUndoStackSize {
            undoStack.removeFirst()
        }
        lastUndoableEvent = event
        showUndoBanner = true

        entryState = .idle
        HapticManager.statRecorded()
    }

    // MARK: - Undo

    func undoLastStat() {
        guard let last = undoStack.popLast() else { return }
        // Reverse score
        let points = last.statType.pointValue
        if points > 0 {
            if last.isOpponentStat {
                game.opponentScore -= points
            } else {
                game.myTeamScore -= points
            }
        }
        last.isDeleted = true
        lastUndoableEvent = undoStack.last
        showUndoBanner = false
        HapticManager.undoPerformed()
    }

    // MARK: - Cancel

    func cancelEntry() {
        entryState = .idle
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

    // MARK: - Add Opponent Player (during game)

    var showingAddOpponent: Bool = false

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

    func advancePeriod() {
        game.currentPeriod += 1
        HapticManager.periodAdvanced()
    }

    func canAdvancePeriod() -> Bool {
        return true // Can always advance (supports OT)
    }

    // MARK: - End Game

    func endGame() {
        game.isComplete = true
    }
}
