import SwiftUI
import SwiftData

/// The live-game scorer — Direction B "Player-First".
/// Reads top-to-bottom: chrome → scoreboard → stat-chip rail → floor 5 →
/// recent plays → pinned opponent quick-score bar. The lineup is the primary
/// tappable surface; there is no team toggle.
struct LiveGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    let game: Game
    @State private var viewModel: LiveGameViewModel?
    @State private var oppFlash = false

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                loadingSkeleton
                    .onAppear {
                        viewModel = LiveGameViewModel(game: game, modelContext: modelContext)
                    }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ vm: LiveGameViewModel) -> some View {
        ZStack(alignment: .bottom) {
            CS.bgStage.ignoresSafeArea()

            VStack(spacing: 0) {
                chrome(vm)

                if oppFlash, let event = vm.lastUndoableEvent {
                    LiveToast(
                        title: "\(vm.displayName(for: event)) · \(vm.description(for: event))",
                        points: event.statType.pointValue,
                        onUndo: {
                            vm.undoLastStat()
                            withAnimation { oppFlash = false }
                        }
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                LiveScoreboard(
                    myTeamName: vm.myTeamName,
                    myScore: vm.myTeamScore,
                    opponentName: vm.opponentName,
                    opponentScore: vm.opponentScore,
                    periodCount: vm.game.format.periodCount,
                    currentPeriod: vm.game.currentPeriod,
                    onSelectPeriod: { vm.requestPeriod($0) }
                )

                StatChipRail(
                    armedStat: vm.armedStat,
                    onTap: { vm.armStat($0) }
                )

                if let armed = vm.armedStat {
                    statArmedBanner(vm, stat: armed)
                }

                floor(vm)

                RecentPlaysCard(
                    events: vm.recentEvents,
                    nameProvider: { vm.displayName(for: $0) },
                    descriptionProvider: { vm.description(for: $0) },
                    canUndo: !vm.undoStack.isEmpty,
                    onUndo: { vm.undoLastStat() }
                )
                .padding(.horizontal, 14)
                .padding(.top, 8)
            }
            .padding(.bottom, 56)

            OppQuickBar(
                opponentName: vm.opponentName,
                flashing: oppFlash,
                onScore: { scoreOpponent(vm, stat: $0) },
                onMore: { vm.showingAddOpponent = true }
            )

            if let armed = vm.armedPlayer, vm.pendingZone == nil {
                PlayerSheet(
                    number: armed.jerseyNumber,
                    name: armed.lastName,
                    onStat: { vm.recordStat($0, for: armed) },
                    onDismiss: { vm.cancelEntry() }
                )
                .padding(.bottom, 56)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeOut(duration: 0.22), value: vm.armedPlayer?.id)
        .animation(.easeOut(duration: 0.18), value: vm.armedStat)
        .sheet(isPresented: zoneSheetBinding(vm)) {
            if let pending = vm.pendingZone {
                ShotChartView(
                    validZones: pending.stat.validShotZones,
                    playerLabel: "#\(pending.player.jerseyNumber) \(pending.player.lastName)",
                    onZoneSelected: { vm.selectZone($0) },
                    onCancel: { vm.skipZone() }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: bind(vm, \.showingSubstitution)) {
            SubstitutionSheet(viewModel: vm)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: bind(vm, \.showingAddOpponent)) {
            QuickAddOpponentView(viewModel: vm)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: bind(vm, \.showingPeriodTransition)) {
            PeriodTransitionSheet(viewModel: vm)
                .presentationDetents([.medium, .large])
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: bind(vm, \.showingAssistPrompt)) {
            AssistPromptSheet(viewModel: vm)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: bind(vm, \.showingBoxScore)) {
            NavigationStack {
                BoxScoreView(game: game)
                    .navigationTitle("Box Score")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("End Game?", isPresented: bind(vm, \.showingEndGameConfirm)) {
            Button("End Game", role: .destructive) {
                vm.endGame()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Final score: \(vm.myTeamScore) – \(vm.opponentScore)")
        }
    }

    // MARK: - Chrome

    @ViewBuilder
    private func chrome(_ vm: LiveGameViewModel) -> some View {
        HStack {
            Button { vm.showingEndGameConfirm = true } label: {
                Text("End")
                    .font(.csUI(15, weight: .medium))
                    .foregroundStyle(CS.danger)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "basketball.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(CS.brand)
                Text("COURTSIDE")
                    .font(.csDisplay(15, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(CS.brand)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    theme.isGymMode.toggle()
                    HapticManager.statRecorded()
                } label: {
                    Image(systemName: theme.isGymMode ? "sun.max.fill" : "sun.max")
                        .foregroundStyle(theme.isGymMode ? CS.amber : CS.inkMute)
                }
                Button { vm.showingBoxScore = true } label: {
                    Image(systemName: "tablecells")
                        .foregroundStyle(CS.brand)
                }
                Menu {
                    Button { vm.showingSubstitution = true } label: {
                        Label("Substitute", systemImage: "arrow.left.arrow.right")
                    }
                    Button(role: .destructive) {
                        vm.showingEndGameConfirm = true
                    } label: {
                        Label("End Game", systemImage: "flag.checkered")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(CS.inkMute)
                }
            }
            .font(.system(size: 18, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }

    // MARK: - Stat-armed banner

    @ViewBuilder
    private func statArmedBanner(_ vm: LiveGameViewModel, stat: StatType) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(CS.made, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("● RECORDING")
                    .font(.csUI(11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(CS.made)
                HStack(spacing: 4) {
                    Text(stat.displayName.uppercased())
                        .font(.csUI(14, weight: .bold))
                        .foregroundStyle(CS.ink)
                    if stat.pointValue > 0 {
                        Text("+\(stat.pointValue)")
                            .font(.csUI(14, weight: .bold))
                            .foregroundStyle(CS.made)
                    }
                    Text("· pick the scorer")
                        .font(.csUI(14))
                        .foregroundStyle(CS.inkMute)
                }
            }

            Spacer()

            Button { vm.cancelEntry() } label: {
                Text("Cancel")
                    .font(.csUI(12, weight: .semibold))
                    .foregroundStyle(CS.inkMute)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(CS.bgSoft, in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CS.made.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(CS.made.opacity(0.4), lineWidth: 1.4)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Floor

    @ViewBuilder
    private func floor(_ vm: LiveGameViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(vm.armedStat == nil ? "FLOOR · TAP A PLAYER" : "TAP THE SCORER")
                    .font(.csUI(11, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(CS.inkDim)
                Spacer()
                Button { vm.showingSubstitution = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Sub")
                    }
                    .font(.csUI(12, weight: .semibold))
                    .foregroundStyle(CS.brand)
                }
            }
            .padding(.top, 4)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(vm.activeLineup, id: \.id) { player in
                        playerRow(vm, player: player)
                    }
                    if vm.activeLineup.isEmpty {
                        Text("No active players. Add a roster in team setup.")
                            .font(.csUI(13))
                            .foregroundStyle(CS.inkMute)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private func playerRow(_ vm: LiveGameViewModel, player: Player) -> some View {
        let stats = vm.line(for: player)
        let mode: FloorPlayerRow.Mode = {
            if vm.armedPlayer?.id == player.id { return .selected }
            if vm.armedStat != nil { return .hint }
            return .normal
        }()
        FloorPlayerRow(
            number: player.jerseyNumber,
            name: player.lastName,
            points: stats.points,
            fouls: stats.fouls,
            fgLine: "\(stats.fieldGoalsMade)/\(stats.fieldGoalsAttempted)",
            foulOut: stats.fouls >= 5,
            mode: mode,
            action: { vm.armPlayer(player) }
        )
    }

    // MARK: - Opponent scoring

    private func scoreOpponent(_ vm: LiveGameViewModel, stat: StatType) {
        vm.recordOpponentQuick(stat)
        withAnimation { oppFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { oppFlash = false }
        }
    }

    // MARK: - Bindings

    private func bind(
        _ vm: LiveGameViewModel,
        _ keyPath: ReferenceWritableKeyPath<LiveGameViewModel, Bool>
    ) -> Binding<Bool> {
        Binding(get: { vm[keyPath: keyPath] }, set: { vm[keyPath: keyPath] = $0 })
    }

    private func zoneSheetBinding(_ vm: LiveGameViewModel) -> Binding<Bool> {
        Binding(
            get: { vm.pendingZone != nil },
            set: { presented in
                if !presented, vm.pendingZone != nil { vm.skipZone() }
            }
        )
    }

    // MARK: - Loading

    private var loadingSkeleton: some View {
        ZStack {
            CS.bgStage.ignoresSafeArea()
            ProgressView()
                .controlSize(.large)
        }
    }
}

// MARK: - Scoreboard

private struct LiveScoreboard: View {
    let myTeamName: String
    let myScore: Int
    let opponentName: String
    let opponentScore: Int
    let periodCount: Int
    let currentPeriod: Int
    var onSelectPeriod: (Int) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            teamLine(name: myTeamName, score: myScore, color: CS.home, reversed: false)

            PeriodStepper(
                count: periodCount,
                current: currentPeriod,
                onSelect: onSelectPeriod
            )

            teamLine(name: opponentName, score: opponentScore, color: CS.away, reversed: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14).strokeBorder(CS.line, lineWidth: 1)
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func teamLine(name: String, score: Int, color: Color, reversed: Bool) -> some View {
        let label = VStack(alignment: reversed ? .trailing : .leading, spacing: 0) {
            Text(name.uppercased())
                .font(.csUI(11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(CS.inkMute)
                .lineLimit(1)
            Text("\(score)")
                .font(.csDisplay(56, weight: .heavy))
                .foregroundStyle(CS.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        let jersey = Jersey(
            number: String(name.prefix(1)).uppercased(),
            color: color,
            size: 28
        )
        HStack(spacing: 8) {
            if reversed { label; jersey } else { jersey; label }
        }
        .frame(maxWidth: .infinity, alignment: reversed ? .trailing : .leading)
    }
}

// MARK: - Stat chip rail

private struct StatChipRail: View {
    let armedStat: StatType?
    var onTap: (StatType) -> Void

    private let chips: [(String, StatType)] = [
        ("2PT", .fieldGoalMade),
        ("3PT", .threePointMade),
        ("FT", .freeThrowMade),
        ("AST", .assist),
        ("REB", .defensiveRebound),
        ("STL", .steal),
        ("BLK", .block),
        ("TO", .turnover),
        ("FOUL", .foul),
    ]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                Text("OR STAT FIRST")
                    .font(.csUI(10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(CS.inkDim)
                    .padding(.trailing, 2)

                ForEach(chips, id: \.0) { label, stat in
                    chip(label: label, stat: stat)
                }
            }
            .padding(.horizontal, 14)
        }
        .scrollIndicators(.hidden)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func chip(label: String, stat: StatType) -> some View {
        let armed = armedStat == stat
        Button { onTap(stat) } label: {
            HStack(spacing: 3) {
                if armed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                }
                Text(label)
                if armed, stat.pointValue > 0 {
                    Text("+\(stat.pointValue)")
                }
            }
            .font(.csUI(12, weight: .bold))
            .foregroundStyle(armed ? .white : CS.inkMute)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(armed ? CS.made : CS.bgSoft, in: Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Recent plays card

private struct RecentPlaysCard: View {
    let events: [StatEvent]
    var nameProvider: (StatEvent) -> String
    var descriptionProvider: (StatEvent) -> String
    let canUndo: Bool
    var onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("RECENT")
                    .font(.csUI(10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(CS.inkDim)
                Spacer()
                Button(action: onUndo) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .font(.csUI(12, weight: .semibold))
                    .foregroundStyle(canUndo ? CS.brand : CS.inkDim)
                }
                .disabled(!canUndo)
            }

            if events.isEmpty {
                Text("No plays yet — tap a player or a stat to start.")
                    .font(.csUI(12))
                    .foregroundStyle(CS.inkMute)
                    .padding(.vertical, 4)
            } else {
                ForEach(events, id: \.id) { event in
                    row(event)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CS.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).strokeBorder(CS.line, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func row(_ event: StatEvent) -> some View {
        let side = event.isOpponentStat ? CS.away : CS.home
        let points = event.statType.pointValue
        HStack(spacing: 8) {
            Text("Q\(event.period)")
                .font(.csMono(11))
                .foregroundStyle(CS.inkDim)
                .frame(width: 30, alignment: .leading)

            RoundedRectangle(cornerRadius: 2)
                .fill(side)
                .frame(width: 3, height: 16)

            Text(nameProvider(event))
                .font(.csUI(12, weight: .bold))
                .foregroundStyle(side)
            Text("· \(descriptionProvider(event))")
                .font(.csUI(12))
                .foregroundStyle(CS.inkMute)
                .lineLimit(1)

            Spacer(minLength: 0)

            if points > 0 {
                Text("+\(points)")
                    .font(.csDisplay(16, weight: .heavy))
                    .foregroundStyle(side)
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Toast

private struct LiveToast: View {
    let title: String
    let points: Int
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(CS.made, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("RECORDED")
                    .font(.csUI(11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(CS.made)
                Text(title)
                    .font(.csUI(14, weight: .semibold))
                    .foregroundStyle(CS.ink)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button(action: onUndo) {
                Text("Undo")
                    .font(.csUI(12, weight: .bold))
                    .foregroundStyle(CS.brand)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(CS.brandSoft, in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CS.made.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(CS.made.opacity(0.5), lineWidth: 1.4)
        )
    }
}
