import Foundation
import SwiftData
import Observation

enum StatEntryState: Equatable {
    case idle
    // Stat-first flow
    case statSelected(StatType, isOpponent: Bool)
    case zoneSelected(StatType, ShotZone, isOpponent: Bool)
    // Player-first flow
    case playerSelected(Player)
    case playerStatSelected(Player, StatType)

    static func == (lhs: StatEntryState, rhs: StatEntryState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.statSelected(lt, lo), .statSelected(rt, ro)):
            return lt == rt && lo == ro
        case let (.zoneSelected(lt, lz, lo), .zoneSelected(rt, rz, ro)):
            return lt == rt && lz == rz && lo == ro
        case let (.playerSelected(lp), .playerSelected(rp)):
            return lp.id == rp.id
        case let (.playerStatSelected(lp, lt), .playerStatSelected(rp, rt)):
            return lp.id == rp.id && lt == rt
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
        case .playerStatSelected(_, let stat): return stat
        default: return nil
        }
    }

    var needsZoneSelection: Bool {
        guard game.trackShotZones else { return false }
        switch entryState {
        case .statSelected(let stat, _):
            return stat.requiresShotZone
        case .playerStatSelected(_, let stat):
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
            return []  // TODO: restore when relationships are back
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
        guard case .statSelected(let stat, let isOpp) = entryState else {
            guard case .playerStatSelected(let player, let stat) = entryState else { return }
            // Player-first flow: zone is last step, commit
            commitStat(stat: stat, zone: zone, player: player, isOpponent: false)
            return
        }

        if isOpp && game.opponentTrackingLevel == .team {
            commitStat(stat: stat, zone: zone, player: nil, isOpponent: true)
        } else {
            entryState = .zoneSelected(stat, zone, isOpponent: isOpp)
        }
    }

    func selectPlayer(_ player: Player) {
        switch entryState {
        // Stat-first: player is final step
        case .statSelected(let stat, let isOpp):
            commitStat(stat: stat, zone: nil, player: player, isOpponent: isOpp)
        case .zoneSelected(let stat, let zone, let isOpp):
            commitStat(stat: stat, zone: zone, player: player, isOpponent: isOpp)

        // Player-first: player is first step
        case .idle:
            if game.statEntryMode == .playerFirst {
                entryState = .playerSelected(player)
                HapticManager.selectionChanged()
            }

        default:
            break
        }
    }

    // MARK: - Stat Entry (Player-First Flow)

    func selectStatForPlayer(_ stat: StatType) {
        guard case .playerSelected(let player) = entryState else { return }

        if stat.requiresShotZone {
            entryState = .playerStatSelected(player, stat)
        } else {
            commitStat(stat: stat, zone: nil, player: player, isOpponent: false)
        }

        HapticManager.selectionChanged()
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
