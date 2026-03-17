import Foundation

struct SnakePoint: Hashable, Equatable, Codable {
    let x: Int
    let y: Int

    func moved(_ direction: SnakeDirection) -> SnakePoint {
        SnakePoint(x: x + direction.dx, y: y + direction.dy)
    }
}

enum SnakeDirection: String, Codable {
    case up
    case down
    case left
    case right

    var dx: Int {
        switch self {
        case .left: -1
        case .right: 1
        case .up, .down: 0
        }
    }

    var dy: Int {
        switch self {
        case .up: -1
        case .down: 1
        case .left, .right: 0
        }
    }

    var opposite: SnakeDirection {
        switch self {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }
}

struct SnakeGameSnapshot: Equatable {
    let boardSize: Int
    let snake: [SnakePoint]
    let food: SnakePoint?
    let direction: SnakeDirection
    let score: Int
    let difficulty: GameDifficulty

    var snakeLength: Int { snake.count }
}

enum TickEvent: Equatable {
    case moved
    case ateFood
    case crashed
    case victory
}

struct TickResult: Equatable {
    let state: SnakeGameSnapshot
    let events: [TickEvent]
    let scoreDelta: Int
    let nextTickInterval: TimeInterval
}

protocol SnakeRandomNumberProviding: AnyObject {
    func nextInt(upperBound: Int) -> Int
}

final class SystemSnakeRandomNumberProvider: SnakeRandomNumberProviding {
    func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int.random(in: 0..<upperBound)
    }
}

final class SequenceSnakeRandomNumberProvider: SnakeRandomNumberProviding {
    private let values: [Int]
    private var index = 0

    init(values: [Int]) {
        self.values = values
    }

    func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        guard !values.isEmpty else { return 0 }

        let value = values[index % values.count]
        index += 1
        return abs(value) % upperBound
    }
}

final class SnakeGameEngine {
    private let randomNumberProvider: SnakeRandomNumberProviding
    private var queuedDirection: SnakeDirection?
    private var isTerminalState = false

    private(set) var snapshot: SnakeGameSnapshot

    init(randomNumberProvider: SnakeRandomNumberProviding = SystemSnakeRandomNumberProvider()) {
        self.randomNumberProvider = randomNumberProvider
        self.snapshot = SnakeGameSnapshot(
            boardSize: 18,
            snake: [SnakePoint(x: 9, y: 9), SnakePoint(x: 8, y: 9), SnakePoint(x: 7, y: 9)],
            food: SnakePoint(x: 12, y: 9),
            direction: .right,
            score: 0,
            difficulty: .classic
        )
    }

    func startNewGame(difficulty: GameDifficulty, boardSize: Int = 18) {
        let center = boardSize / 2
        let snake = [
            SnakePoint(x: center, y: center),
            SnakePoint(x: center - 1, y: center),
            SnakePoint(x: center - 2, y: center)
        ]

        snapshot = SnakeGameSnapshot(
            boardSize: boardSize,
            snake: snake,
            food: nextFood(excluding: snake, boardSize: boardSize),
            direction: .right,
            score: 0,
            difficulty: difficulty
        )
        queuedDirection = nil
        isTerminalState = false
    }

    func queueDirection(_ direction: SnakeDirection) {
        let referenceDirection = queuedDirection ?? snapshot.direction
        guard direction != referenceDirection.opposite else { return }
        queuedDirection = direction
    }

    func advanceOneTick() -> TickResult {
        guard !isTerminalState else {
            return TickResult(
                state: snapshot,
                events: [],
                scoreDelta: 0,
                nextTickInterval: tickInterval(for: snapshot.difficulty, score: snapshot.score)
            )
        }

        let activeDirection = resolvedDirection()
        let newHead = snapshot.snake[0].moved(activeDirection)

        guard isInsideBoard(newHead, boardSize: snapshot.boardSize) else {
            return crashResult(direction: activeDirection)
        }

        let grew = snapshot.food == newHead
        let collisionBody = grew ? snapshot.snake : Array(snapshot.snake.dropLast())
        guard !collisionBody.contains(newHead) else {
            return crashResult(direction: activeDirection)
        }

        var snake = snapshot.snake
        snake.insert(newHead, at: 0)
        var score = snapshot.score
        var food = snapshot.food
        var events: [TickEvent] = [.moved]
        var scoreDelta = 0

        if grew {
            score += 1
            scoreDelta = 1
            events.append(.ateFood)
            food = nextFood(excluding: snake, boardSize: snapshot.boardSize)
            if food == nil {
                events.append(.victory)
                isTerminalState = true
            }
        } else {
            snake.removeLast()
        }

        let nextState = SnakeGameSnapshot(
            boardSize: snapshot.boardSize,
            snake: snake,
            food: food,
            direction: activeDirection,
            score: score,
            difficulty: snapshot.difficulty
        )
        snapshot = nextState

        return TickResult(
            state: nextState,
            events: events,
            scoreDelta: scoreDelta,
            nextTickInterval: tickInterval(for: nextState.difficulty, score: nextState.score)
        )
    }

    internal func setSnapshotForTesting(_ snapshot: SnakeGameSnapshot, crashed: Bool = false) {
        self.snapshot = snapshot
        self.queuedDirection = nil
        self.isTerminalState = crashed
    }

    private func crashResult(direction: SnakeDirection) -> TickResult {
        isTerminalState = true
        let crashedState = SnakeGameSnapshot(
            boardSize: snapshot.boardSize,
            snake: snapshot.snake,
            food: snapshot.food,
            direction: direction,
            score: snapshot.score,
            difficulty: snapshot.difficulty
        )
        snapshot = crashedState
        return TickResult(
            state: crashedState,
            events: [.crashed],
            scoreDelta: 0,
            nextTickInterval: tickInterval(for: crashedState.difficulty, score: crashedState.score)
        )
    }

    private func resolvedDirection() -> SnakeDirection {
        let direction = queuedDirection ?? snapshot.direction
        queuedDirection = nil
        return direction
    }

    private func isInsideBoard(_ point: SnakePoint, boardSize: Int) -> Bool {
        (0..<boardSize).contains(point.x) && (0..<boardSize).contains(point.y)
    }

    private func nextFood(excluding snake: [SnakePoint], boardSize: Int) -> SnakePoint? {
        let occupied = Set(snake)
        var available: [SnakePoint] = []
        available.reserveCapacity(boardSize * boardSize)

        for y in 0..<boardSize {
            for x in 0..<boardSize {
                let point = SnakePoint(x: x, y: y)
                if !occupied.contains(point) {
                    available.append(point)
                }
            }
        }

        guard !available.isEmpty else { return nil }

        let index = randomNumberProvider.nextInt(upperBound: available.count)
        return available[index]
    }

    private func tickInterval(for difficulty: GameDifficulty, score: Int) -> TimeInterval {
        max(difficulty.minimumTick, difficulty.baseTick - (Double(score) * difficulty.accelerationPerFood))
    }
}
