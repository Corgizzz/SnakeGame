import XCTest
@testable import SnakeGame

final class SnakeGameEngineTests: XCTestCase {
    func testStartNewGameCreatesCenteredSnakeAndValidFood() {
        let engine = SnakeGameEngine(randomNumberProvider: SequenceSnakeRandomNumberProvider(values: [0]))

        engine.startNewGame(difficulty: .classic, boardSize: 10)

        XCTAssertEqual(engine.snapshot.snake, [
            SnakePoint(x: 5, y: 5),
            SnakePoint(x: 4, y: 5),
            SnakePoint(x: 3, y: 5)
        ])
        XCTAssertEqual(engine.snapshot.direction, .right)
        XCTAssertEqual(engine.snapshot.score, 0)
        XCTAssertFalse(engine.snapshot.snake.contains(engine.snapshot.food))
    }

    func testAdvanceOneTickMovesOneCell() {
        let engine = SnakeGameEngine(randomNumberProvider: SequenceSnakeRandomNumberProvider(values: [0]))
        engine.startNewGame(difficulty: .classic, boardSize: 10)

        let result = engine.advanceOneTick()

        XCTAssertEqual(result.events, [.moved])
        XCTAssertEqual(result.state.snake.first, SnakePoint(x: 6, y: 5))
        XCTAssertEqual(result.state.snake.count, 3)
        XCTAssertEqual(result.scoreDelta, 0)
    }

    func testConsecutiveReverseInputsAreIgnored() {
        let engine = SnakeGameEngine(randomNumberProvider: SequenceSnakeRandomNumberProvider(values: [0]))
        engine.startNewGame(difficulty: .classic, boardSize: 10)

        engine.queueDirection(.up)
        engine.queueDirection(.down)
        let result = engine.advanceOneTick()

        XCTAssertEqual(result.state.direction, .up)
        XCTAssertEqual(result.state.snake.first, SnakePoint(x: 5, y: 4))
    }

    func testEatingFoodIncreasesScoreAndRespawnsFoodOffSnake() {
        let engine = SnakeGameEngine(randomNumberProvider: SequenceSnakeRandomNumberProvider(values: [0, 4]))
        engine.startNewGame(difficulty: .classic, boardSize: 10)
        engine.setSnapshotForTesting(
            SnakeGameSnapshot(
                boardSize: 10,
                snake: [SnakePoint(x: 5, y: 5), SnakePoint(x: 4, y: 5), SnakePoint(x: 3, y: 5)],
                food: SnakePoint(x: 6, y: 5),
                direction: .right,
                score: 0,
                difficulty: .classic
            )
        )

        let result = engine.advanceOneTick()

        XCTAssertEqual(result.scoreDelta, 1)
        XCTAssertEqual(result.state.score, 1)
        XCTAssertEqual(result.state.snake.count, 4)
        XCTAssertTrue(result.events.contains(.ateFood))
        XCTAssertFalse(result.state.snake.contains(result.state.food))
    }

    func testCrashEventReturnedForWallCollision() {
        let engine = SnakeGameEngine(randomNumberProvider: SequenceSnakeRandomNumberProvider(values: [0]))
        engine.setSnapshotForTesting(
            SnakeGameSnapshot(
                boardSize: 4,
                snake: [SnakePoint(x: 3, y: 1), SnakePoint(x: 2, y: 1), SnakePoint(x: 1, y: 1)],
                food: SnakePoint(x: 0, y: 0),
                direction: .right,
                score: 0,
                difficulty: .classic
            )
        )

        let result = engine.advanceOneTick()

        XCTAssertEqual(result.events, [.crashed])
    }

    func testDifficultyChangesTickInterval() {
        let chill = SnakeGameEngine(randomNumberProvider: SequenceSnakeRandomNumberProvider(values: [0]))
        chill.startNewGame(difficulty: .chill, boardSize: 10)
        let chillTick = chill.advanceOneTick().nextTickInterval

        let frenzy = SnakeGameEngine(randomNumberProvider: SequenceSnakeRandomNumberProvider(values: [0]))
        frenzy.startNewGame(difficulty: .frenzy, boardSize: 10)
        let frenzyTick = frenzy.advanceOneTick().nextTickInterval

        XCTAssertGreaterThan(chillTick, frenzyTick)
    }

    func testDeterministicRandomSequenceProducesSameFood() {
        let providerA = SequenceSnakeRandomNumberProvider(values: [3, 7, 11])
        let providerB = SequenceSnakeRandomNumberProvider(values: [3, 7, 11])
        let engineA = SnakeGameEngine(randomNumberProvider: providerA)
        let engineB = SnakeGameEngine(randomNumberProvider: providerB)

        engineA.startNewGame(difficulty: .classic, boardSize: 10)
        engineB.startNewGame(difficulty: .classic, boardSize: 10)

        XCTAssertEqual(engineA.snapshot.food, engineB.snapshot.food)
    }
}
