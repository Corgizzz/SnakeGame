import SwiftUI
import XCTest
@testable import SnakeGame

@MainActor
final class SnakeGameModelTests: XCTestCase {
    func testStartPauseResumeRestartAndMenuTransitions() {
        let model = makeModel()

        model.startGame()
        XCTAssertEqual(model.sessionState, .countdown)

        model.processCountdownStep()
        model.processCountdownStep()
        model.processCountdownStep()
        XCTAssertEqual(model.sessionState, .running)

        model.togglePause()
        XCTAssertEqual(model.sessionState, .paused)

        model.togglePause()
        XCTAssertEqual(model.sessionState, .countdown)

        model.restartGame()
        XCTAssertEqual(model.sessionState, .countdown)

        model.returnToMenu()
        XCTAssertEqual(model.sessionState, .menu)
    }

    func testScenePhaseBackgroundAndForegroundResumeViaCountdown() {
        let model = makeModel()
        model.startGame()
        model.processCountdownStep()
        model.processCountdownStep()
        model.processCountdownStep()
        XCTAssertEqual(model.sessionState, .running)

        model.handleScenePhaseChange(.background)
        XCTAssertEqual(model.sessionState, .paused)

        model.handleScenePhaseChange(.active)
        XCTAssertEqual(model.sessionState, .countdown)
    }

    func testOnlyOneActiveTimerExists() {
        let model = makeModel()
        model.startGame()
        XCTAssertTrue(model.isTimerActiveForTesting)
        XCTAssertEqual(model.activeLoopKind, .countdown)

        model.processCountdownStep()
        model.processCountdownStep()
        model.processCountdownStep()

        XCTAssertTrue(model.isTimerActiveForTesting)
        XCTAssertEqual(model.activeLoopKind, .running)
    }

    func testStatsAndBestScorePersistOnceOnCrash() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let model = makeModel(defaults: defaults)

        model.startGame()
        model.processCountdownStep()
        model.processCountdownStep()
        model.processCountdownStep()
        forceCrash(on: model)

        XCTAssertEqual(model.sessionState, .gameOver)
        XCTAssertEqual(model.recentStats.totalGames, 1)
        XCTAssertEqual(model.bestScore, 0)

        forceCrash(on: model)
        XCTAssertEqual(model.recentStats.totalGames, 1)
    }

    private func makeModel(defaults: UserDefaults? = nil) -> SnakeGameModel {
        let defaults = defaults ?? UserDefaults(suiteName: UUID().uuidString)!
        let settings = GameSettingsStore(defaults: defaults)
        let stats = GameStatsStore(defaults: defaults, storageKey: "tests.stats")
        let feedback = SilentFeedback()
        let engine = SnakeGameEngine(randomNumberProvider: SequenceSnakeRandomNumberProvider(values: [0, 1, 2]))
        return SnakeGameModel(settingsStore: settings, statsStore: stats, feedback: feedback, engine: engine)
    }

    private func forceCrash(on model: SnakeGameModel) {
        model.setSnapshotForTesting(
            SnakeGameSnapshot(
                boardSize: 4,
                snake: [SnakePoint(x: 3, y: 1), SnakePoint(x: 2, y: 1), SnakePoint(x: 1, y: 1)],
                food: SnakePoint(x: 0, y: 0),
                direction: .right,
                score: 0,
                difficulty: model.selectedDifficulty
            )
        )
        model.processGameTick()
    }
}

@MainActor
private final class SilentFeedback: GameFeedbackProviding {
    func handle(_ event: GameEvent, soundEnabled: Bool, hapticsEnabled: Bool) {}
}
