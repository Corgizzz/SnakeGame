import Foundation
import SwiftUI

@MainActor
final class SnakeGameModel: ObservableObject {
    enum LoopKind: Equatable {
        case countdown
        case running
    }

    @Published private(set) var sessionState: GameSessionState = .menu
    @Published private(set) var snapshot: SnakeGameSnapshot
    @Published private(set) var currentScore = 0
    @Published private(set) var bestScore = 0
    @Published var selectedDifficulty: GameDifficulty = .classic
    @Published private(set) var recentStats: GameStatsSnapshot
    @Published private(set) var countdownValue: Int?
    @Published private(set) var lastRoundSummary: GameRoundSummary?
    @Published private(set) var lastCollectedScoreDelta: Int?

    let settingsStore: GameSettingsStore

    private let statsStore: GameStatsStore
    private let feedback: GameFeedbackProviding
    private let engine: SnakeGameEngine
    private let countdownStart = 3
    private var timer: Timer?
    private var currentTickInterval: TimeInterval
    private var shouldResumeAfterBecomingActive = false
    private var didRecordCurrentRound = false

    internal private(set) var activeLoopKind: LoopKind?

    init(
        settingsStore: GameSettingsStore,
        statsStore: GameStatsStore,
        feedback: GameFeedbackProviding,
        engine: SnakeGameEngine
    ) {
        self.settingsStore = settingsStore
        self.statsStore = statsStore
        self.feedback = feedback
        self.engine = engine
        self.snapshot = engine.snapshot
        self.currentTickInterval = GameDifficulty.classic.baseTick
        self.recentStats = statsStore.snapshot
        self.bestScore = statsStore.bestScore(for: .classic)
    }

    convenience init() {
        self.init(
            settingsStore: GameSettingsStore(),
            statsStore: GameStatsStore(),
            feedback: GameFeedbackManager(),
            engine: SnakeGameEngine()
        )
    }

    deinit {
        timer?.invalidate()
    }

    var boardSize: Int { snapshot.boardSize }

    var speedLabel: String {
        let base = max(selectedDifficulty.baseTick, 0.01)
        let multiplier = max(1.0, base / max(currentTickInterval, 0.01))
        return String(format: "%.1fx", multiplier)
    }

    var canTogglePause: Bool {
        sessionState == .running || sessionState == .paused
    }

    func startGame() {
        beginRound(with: selectedDifficulty)
    }

    func restartGame() {
        beginRound(with: selectedDifficulty)
    }

    func returnToMenu() {
        invalidateTimer()
        countdownValue = nil
        sessionState = .menu
        shouldResumeAfterBecomingActive = false
        didRecordCurrentRound = false
        lastRoundSummary = nil
        lastCollectedScoreDelta = nil
        bestScore = statsStore.bestScore(for: selectedDifficulty)
        recentStats = statsStore.snapshot
    }

    func togglePause() {
        switch sessionState {
        case .running:
            pause()
        case .paused:
            startCountdown(resumeAfterCountdown: true)
        case .menu, .countdown, .gameOver:
            break
        }
    }

    func turn(_ direction: SnakeDirection) {
        guard sessionState == .running else { return }
        engine.queueDirection(direction)
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            handleSceneDidBecomeActive()
        case .background, .inactive:
            handleSceneWillResignActive()
        @unknown default:
            handleSceneWillResignActive()
        }
    }

    internal func handleSceneWillResignActive() {
        shouldResumeAfterBecomingActive = sessionState == .running
        if sessionState == .running || sessionState == .countdown {
            pause()
        }
    }

    internal func handleSceneDidBecomeActive() {
        guard shouldResumeAfterBecomingActive, sessionState == .paused else { return }
        shouldResumeAfterBecomingActive = false
        startCountdown(resumeAfterCountdown: true)
    }

    internal func processCountdownStep() {
        guard sessionState == .countdown else { return }
        let nextValue = (countdownValue ?? countdownStart) - 1
        if nextValue > 0 {
            countdownValue = nextValue
            return
        }

        countdownValue = nil
        startRunningLoop(sendRoundStartedEvent: true)
    }

    internal func processGameTick() {
        guard sessionState == .running else { return }
        let result = engine.advanceOneTick()
        apply(result: result)
    }

    internal var isTimerActiveForTesting: Bool {
        timer != nil
    }

    internal func setSnapshotForTesting(_ snapshot: SnakeGameSnapshot) {
        selectedDifficulty = snapshot.difficulty
        engine.setSnapshotForTesting(snapshot)
        self.snapshot = snapshot
        currentScore = snapshot.score
        currentTickInterval = tickInterval(for: snapshot.score, difficulty: snapshot.difficulty)
    }

    private func beginRound(with difficulty: GameDifficulty) {
        invalidateTimer()
        selectedDifficulty = difficulty
        engine.startNewGame(difficulty: difficulty, boardSize: 18)
        snapshot = engine.snapshot
        currentScore = 0
        currentTickInterval = difficulty.baseTick
        sessionState = .countdown
        countdownValue = countdownStart
        lastRoundSummary = nil
        lastCollectedScoreDelta = nil
        didRecordCurrentRound = false
        shouldResumeAfterBecomingActive = false
        bestScore = statsStore.bestScore(for: difficulty)
        recentStats = statsStore.snapshot
        startCountdown(resumeAfterCountdown: false)
    }

    private func pause() {
        guard sessionState == .running || sessionState == .countdown else { return }
        invalidateTimer()
        countdownValue = nil
        sessionState = .paused
    }

    private func startCountdown(resumeAfterCountdown: Bool) {
        invalidateTimer()
        sessionState = .countdown
        countdownValue = countdownStart
        scheduleTimer(kind: .countdown, interval: 1.0) { [weak self] in
            self?.processCountdownStep()
        }
        if !resumeAfterCountdown {
            currentTickInterval = selectedDifficulty.baseTick
        }
    }

    private func startRunningLoop(sendRoundStartedEvent: Bool) {
        sessionState = .running
        currentTickInterval = tickInterval(for: snapshot.score, difficulty: snapshot.difficulty)
        scheduleRunningTimer()
        if sendRoundStartedEvent {
            feedback.handle(
                .roundStarted,
                soundEnabled: settingsStore.soundEnabled,
                hapticsEnabled: settingsStore.hapticsEnabled
            )
        }
    }

    private func scheduleRunningTimer() {
        scheduleTimer(kind: .running, interval: currentTickInterval) { [weak self] in
            self?.processGameTick()
        }
    }

    private func scheduleTimer(kind: LoopKind, interval: TimeInterval, action: @escaping () -> Void) {
        invalidateTimer()
        activeLoopKind = kind
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            action()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
        activeLoopKind = nil
    }

    private func apply(result: TickResult) {
        snapshot = result.state
        currentScore = result.state.score

        if result.events.contains(.ateFood) {
            lastCollectedScoreDelta = result.scoreDelta
            feedback.handle(
                .foodEaten,
                soundEnabled: settingsStore.soundEnabled,
                hapticsEnabled: settingsStore.hapticsEnabled
            )
        } else {
            lastCollectedScoreDelta = nil
        }

        if result.events.contains(.victory) {
            finishRound(outcome: .victory)
            return
        }

        if result.events.contains(.crashed) {
            finishRound(outcome: .crash)
            return
        }

        let nextInterval = result.nextTickInterval
        if abs(nextInterval - currentTickInterval) > 0.0001 {
            currentTickInterval = nextInterval
            scheduleRunningTimer()
        }
    }

    private func finishRound(outcome: GameRoundOutcome) {
        invalidateTimer()
        sessionState = .gameOver

        guard !didRecordCurrentRound else { return }
        didRecordCurrentRound = true

        let snakeLength = snapshot.snakeLength
        let isNewRecord = statsStore.recordRound(
            difficulty: selectedDifficulty,
            score: currentScore,
            snakeLength: snakeLength
        )
        recentStats = statsStore.snapshot
        bestScore = statsStore.bestScore(for: selectedDifficulty)
        lastRoundSummary = GameRoundSummary(
            outcome: outcome,
            difficulty: selectedDifficulty,
            score: currentScore,
            bestScore: bestScore,
            longestSnakeLength: snakeLength,
            isNewRecord: isNewRecord
        )
        feedback.handle(
            outcome == .victory ? .victory : .gameOver,
            soundEnabled: settingsStore.soundEnabled,
            hapticsEnabled: settingsStore.hapticsEnabled
        )
    }

    private func tickInterval(for score: Int, difficulty: GameDifficulty) -> TimeInterval {
        max(difficulty.minimumTick, difficulty.baseTick - (Double(score) * difficulty.accelerationPerFood))
    }
}

enum GameSessionState: Equatable {
    case menu
    case countdown
    case running
    case paused
    case gameOver
}

struct GameRoundSummary: Equatable {
    let outcome: GameRoundOutcome
    let difficulty: GameDifficulty
    let score: Int
    let bestScore: Int
    let longestSnakeLength: Int
    let isNewRecord: Bool
}

enum GameRoundOutcome: Equatable {
    case crash
    case victory
}
