import SwiftUI

@main
struct SnakeGameApp: App {
    @StateObject private var screenshotPreview = ScreenshotPreviewCoordinator.shared

    var body: some Scene {
        WindowGroup {
            SnakeGameRootView()
                .environmentObject(screenshotPreview)
        }
    }
}

private struct SnakeGameRootView: View {
    @EnvironmentObject private var screenshotPreview: ScreenshotPreviewCoordinator

    var body: some View {
        Group {
            if let scenario = screenshotPreview.scenario {
                ScreenshotScenarioView(scenario: scenario)
            } else {
                ContentView()
            }
        }
    }
}

@MainActor
final class ScreenshotPreviewCoordinator: ObservableObject {
    static let shared = ScreenshotPreviewCoordinator()

    @Published var scenario: ScreenshotScenario?

    private init() {}
}

enum ScreenshotScenario {
    case menu
    case gameplay
    case result
}

private struct ScreenshotScenarioView: View {
    let scenario: ScreenshotScenario

    var body: some View {
        ZStack {
            PreviewBackground()
                .ignoresSafeArea()

            switch scenario {
            case .menu:
                ScreenshotMenuView()
            case .gameplay:
                ScreenshotGameplayView()
            case .result:
                ScreenshotResultView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct PreviewBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.08, blue: 0.14),
                Color(red: 0.07, green: 0.15, blue: 0.11),
                Color(red: 0.13, green: 0.10, blue: 0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct ScreenshotMenuView: View {
    @StateObject private var settingsStore: GameSettingsStore

    private let stats = GameStatsSnapshot(
        bestScores: DifficultyBestScores(chill: 9, classic: 17, frenzy: 24),
        recentRounds: [
            RoundRecord(id: UUID(), difficulty: .classic, score: 17, snakeLength: 20, playedAt: .now),
            RoundRecord(id: UUID(), difficulty: .frenzy, score: 24, snakeLength: 27, playedAt: .now.addingTimeInterval(-3600)),
            RoundRecord(id: UUID(), difficulty: .chill, score: 9, snakeLength: 12, playedAt: .now.addingTimeInterval(-7200))
        ],
        longestSnakeLength: 27,
        totalGames: 18
    )

    init() {
        let defaults = UserDefaults(suiteName: "screenshot.preview.menu")!
        defaults.removePersistentDomain(forName: "screenshot.preview.menu")
        let settings = GameSettingsStore(defaults: defaults)
        settings.soundEnabled = true
        settings.hapticsEnabled = true
        _settingsStore = StateObject(wrappedValue: settings)
    }

    var body: some View {
        MainMenuView(
            selectedDifficulty: .constant(.classic),
            settingsStore: settingsStore,
            stats: stats,
            isRegular: false,
            onStart: {}
        )
        .padding(18)
    }
}

private struct ScreenshotGameplayView: View {
    private let snapshot = SnakeGameSnapshot(
        boardSize: 18,
        snake: [
            SnakePoint(x: 11, y: 8), SnakePoint(x: 10, y: 8), SnakePoint(x: 9, y: 8),
            SnakePoint(x: 8, y: 8), SnakePoint(x: 8, y: 9), SnakePoint(x: 8, y: 10),
            SnakePoint(x: 9, y: 10), SnakePoint(x: 10, y: 10), SnakePoint(x: 11, y: 10),
            SnakePoint(x: 12, y: 10)
        ],
        food: SnakePoint(x: 13, y: 6),
        direction: .right,
        score: 12,
        difficulty: .classic
    )

    private let stats = GameStatsSnapshot(
        bestScores: DifficultyBestScores(chill: 9, classic: 17, frenzy: 24),
        recentRounds: [],
        longestSnakeLength: 27,
        totalGames: 18
    )

    var body: some View {
        HStack(spacing: 28) {
            GameBoardView(
                snapshot: snapshot,
                sessionState: .running,
                countdownValue: nil,
                roundOutcome: nil,
                scoreDelta: nil,
                onSwipe: { _ in }
            )
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 680)

            VStack(spacing: 18) {
                GameHUDView(
                    difficulty: .classic,
                    score: 12,
                    bestScore: 17,
                    speedLabel: "1.6x",
                    sessionState: .running,
                    totalGames: 18,
                    onMenu: {},
                    onRestart: {},
                    onTogglePause: {},
                    canTogglePause: true,
                    compact: false
                )

                DirectionPadView(onUp: {}, onLeft: {}, onDown: {}, onRight: {})
                ScreenshotStatsCard(stats: stats)
            }
            .frame(maxWidth: 360)
        }
        .padding(28)
        .frame(maxWidth: 1100, maxHeight: .infinity)
    }
}

private struct ScreenshotResultView: View {
    private let snapshot = SnakeGameSnapshot(
        boardSize: 18,
        snake: [
            SnakePoint(x: 15, y: 4), SnakePoint(x: 14, y: 4), SnakePoint(x: 13, y: 4),
            SnakePoint(x: 12, y: 4), SnakePoint(x: 11, y: 4), SnakePoint(x: 10, y: 4),
            SnakePoint(x: 9, y: 4), SnakePoint(x: 8, y: 4), SnakePoint(x: 7, y: 4),
            SnakePoint(x: 6, y: 4), SnakePoint(x: 5, y: 4), SnakePoint(x: 4, y: 4),
            SnakePoint(x: 3, y: 4), SnakePoint(x: 3, y: 5), SnakePoint(x: 3, y: 6),
            SnakePoint(x: 4, y: 6), SnakePoint(x: 5, y: 6), SnakePoint(x: 6, y: 6),
            SnakePoint(x: 7, y: 6), SnakePoint(x: 8, y: 6)
        ],
        food: nil,
        direction: .right,
        score: 24,
        difficulty: .frenzy
    )

    private let summary = GameRoundSummary(
        outcome: .victory,
        difficulty: .frenzy,
        score: 24,
        bestScore: 24,
        longestSnakeLength: 20,
        isNewRecord: true
    )

    private let stats = GameStatsSnapshot(
        bestScores: DifficultyBestScores(chill: 9, classic: 17, frenzy: 24),
        recentRounds: [],
        longestSnakeLength: 27,
        totalGames: 18
    )

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                GameHUDView(
                    difficulty: .frenzy,
                    score: 24,
                    bestScore: 24,
                    speedLabel: "2.1x",
                    sessionState: .gameOver,
                    totalGames: 18,
                    onMenu: {},
                    onRestart: {},
                    onTogglePause: {},
                    canTogglePause: false,
                    compact: true
                )

                GameBoardView(
                    snapshot: snapshot,
                    sessionState: .gameOver,
                    countdownValue: nil,
                    roundOutcome: .victory,
                    scoreDelta: nil,
                    onSwipe: { _ in }
                )
                .aspectRatio(1, contentMode: .fit)

                DirectionPadView(onUp: {}, onLeft: {}, onDown: {}, onRight: {})
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: 760, maxHeight: .infinity, alignment: .top)
            .padding(18)

            GameOverOverlayView(
                summary: summary,
                recentStats: stats,
                onRestart: {},
                onMenu: {}
            )
        }
    }
}

private struct ScreenshotStatsCard: View {
    let stats: GameStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Session Stats")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            row("Rounds", "\(stats.totalGames)")
            row("Longest Snake", "\(stats.longestSnakeLength)")
            row("Chill Best", "\(stats.bestScores[.chill])")
            row("Classic Best", "\(stats.bestScores[.classic])")
            row("Frenzy Best", "\(stats.bestScores[.frenzy])")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .font(.system(size: 17, weight: .semibold, design: .rounded))
    }
}
