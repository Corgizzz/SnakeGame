import Combine
import Foundation

struct DifficultyBestScores: Codable, Equatable {
    var chill: Int = 0
    var classic: Int = 0
    var frenzy: Int = 0

    subscript(_ difficulty: GameDifficulty) -> Int {
        get {
            switch difficulty {
            case .chill: chill
            case .classic: classic
            case .frenzy: frenzy
            }
        }
        set {
            switch difficulty {
            case .chill: chill = newValue
            case .classic: classic = newValue
            case .frenzy: frenzy = newValue
            }
        }
    }
}

struct RoundRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let difficulty: GameDifficulty
    let score: Int
    let snakeLength: Int
    let playedAt: Date
}

struct GameStatsSnapshot: Codable, Equatable {
    var bestScores: DifficultyBestScores = DifficultyBestScores()
    var recentRounds: [RoundRecord] = []
    var longestSnakeLength: Int = 0
    var totalGames: Int = 0

    static let empty = GameStatsSnapshot()
}

@MainActor
final class GameStatsStore: ObservableObject {
    @Published private(set) var snapshot: GameStatsSnapshot

    private let defaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard, storageKey: String = "snake.stats") {
        self.defaults = defaults
        self.storageKey = storageKey

        if let data = defaults.data(forKey: storageKey),
           let decoded = try? decoder.decode(GameStatsSnapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = .empty
        }
    }

    func bestScore(for difficulty: GameDifficulty) -> Int {
        snapshot.bestScores[difficulty]
    }

    @discardableResult
    func recordRound(difficulty: GameDifficulty, score: Int, snakeLength: Int, playedAt: Date = .now) -> Bool {
        let currentBest = snapshot.bestScores[difficulty]
        let isNewRecord = score > currentBest
        snapshot.bestScores[difficulty] = max(currentBest, score)
        snapshot.longestSnakeLength = max(snapshot.longestSnakeLength, snakeLength)
        snapshot.totalGames += 1
        snapshot.recentRounds.insert(
            RoundRecord(id: UUID(), difficulty: difficulty, score: score, snakeLength: snakeLength, playedAt: playedAt),
            at: 0
        )
        snapshot.recentRounds = Array(snapshot.recentRounds.prefix(10))
        persist()
        return isNewRecord
    }

    private func persist() {
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
