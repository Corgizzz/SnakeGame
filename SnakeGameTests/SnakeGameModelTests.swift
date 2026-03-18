import SwiftUI
import UIKit
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
        XCTAssertEqual(model.lastRoundSummary?.outcome, .crash)

        forceCrash(on: model)
        XCTAssertEqual(model.recentStats.totalGames, 1)
    }

    func testVictoryRecordsRoundAndCreatesVictorySummary() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let model = makeModel(defaults: defaults)

        model.startGame()
        model.processCountdownStep()
        model.processCountdownStep()
        model.processCountdownStep()
        forceVictory(on: model)

        XCTAssertEqual(model.sessionState, .gameOver)
        XCTAssertEqual(model.currentScore, 4)
        XCTAssertEqual(model.recentStats.totalGames, 1)
        XCTAssertEqual(model.bestScore, 4)
        XCTAssertEqual(model.lastRoundSummary?.outcome, .victory)
    }

    override func tearDown() {
        ScreenshotPreviewCoordinator.shared.scenario = nil
        super.tearDown()
    }

    func testCaptureMenuScreenshotOnPhone() throws {
        try captureScreenshot(
            named: "menu-iphone",
            scenario: .menu,
            expectedIdiom: .phone
        )
    }

    func testCaptureResultScreenshotOnPhone() throws {
        try captureScreenshot(
            named: "result-iphone",
            scenario: .result,
            expectedIdiom: .phone
        )
    }

    func testCaptureGameplayScreenshotOnPad() throws {
        try captureScreenshot(
            named: "gameplay-ipad",
            scenario: .gameplay,
            expectedIdiom: .pad
        )
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

    private func forceVictory(on model: SnakeGameModel) {
        model.setSnapshotForTesting(
            SnakeGameSnapshot(
                boardSize: 2,
                snake: [
                    SnakePoint(x: 1, y: 0),
                    SnakePoint(x: 0, y: 0),
                    SnakePoint(x: 0, y: 1)
                ],
                food: SnakePoint(x: 1, y: 1),
                direction: .down,
                score: 3,
                difficulty: model.selectedDifficulty
            )
        )
        model.processGameTick()
    }

    private func captureScreenshot(
        named: String,
        scenario: ScreenshotScenario,
        expectedIdiom: UIUserInterfaceIdiom
    ) throws {
        guard UIDevice.current.userInterfaceIdiom == expectedIdiom else {
            throw XCTSkip("Screenshot '\(named)' only runs on \(expectedIdiom == .pad ? "iPad" : "iPhone") simulators.")
        }

        ScreenshotPreviewCoordinator.shared.scenario = scenario
        RunLoop.main.run(until: Date().addingTimeInterval(1.0))

        let image = try makeWindowSnapshot()
        let attachment = XCTAttachment(image: image)
        attachment.name = named
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func makeWindowSnapshot() throws -> UIImage {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = windowScene.windows.first(where: \.isKeyWindow) ?? windowScene.windows.first else {
            throw XCTSkip("No active UIWindow is available for screenshot capture.")
        }

        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }
}

@MainActor
private final class SilentFeedback: GameFeedbackProviding {
    func handle(_ event: GameEvent, soundEnabled: Bool, hapticsEnabled: Bool) {}
}
