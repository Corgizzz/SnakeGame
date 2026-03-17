import SwiftUI

struct ContentView: View {
    @StateObject private var game = SnakeGameModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            let isRegular = horizontalSizeClass == .regular || proxy.size.width > 900

            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                Group {
                    if game.sessionState == .menu {
                        MainMenuView(
                            selectedDifficulty: $game.selectedDifficulty,
                            settingsStore: game.settingsStore,
                            stats: game.recentStats,
                            isRegular: isRegular,
                            onStart: game.startGame
                        )
                    } else {
                        gameScreen(isRegular: isRegular)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(isRegular ? 28 : 18)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, newPhase in
            game.handleScenePhaseChange(newPhase)
        }
    }

    private var backgroundGradient: some View {
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

    private func gameScreen(isRegular: Bool) -> some View {
        Group {
            if isRegular {
                HStack(spacing: 28) {
                    boardLayer
                        .frame(maxWidth: 680)
                    sidePanel
                        .frame(maxWidth: 360)
                }
                .frame(maxWidth: 1100, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(spacing: 18) {
                    GameHUDView(
                        difficulty: game.selectedDifficulty,
                        score: game.currentScore,
                        bestScore: game.bestScore,
                        speedLabel: game.speedLabel,
                        sessionState: game.sessionState,
                        totalGames: game.recentStats.totalGames,
                        onMenu: game.returnToMenu,
                        onRestart: game.restartGame,
                        onTogglePause: game.togglePause,
                        canTogglePause: game.canTogglePause,
                        compact: true
                    )
                    boardLayer
                    DirectionPadView(
                        onUp: { game.turn(.up) },
                        onLeft: { game.turn(.left) },
                        onDown: { game.turn(.down) },
                        onRight: { game.turn(.right) }
                    )
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: 760, maxHeight: .infinity, alignment: .top)
            }
        }
        .overlay(alignment: .center) {
            if let summary = game.lastRoundSummary, game.sessionState == .gameOver {
                GameOverOverlayView(
                    summary: summary,
                    recentStats: game.recentStats,
                    onRestart: game.restartGame,
                    onMenu: game.returnToMenu
                )
                .transition(.scale(scale: 0.88).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: game.sessionState)
        .overlay {
            KeyboardInputView { direction in
                game.turn(direction)
            }
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var boardLayer: some View {
        GameBoardView(
            snapshot: game.snapshot,
            sessionState: game.sessionState,
            countdownValue: game.countdownValue,
            onSwipe: game.turn
        )
        .aspectRatio(1, contentMode: .fit)
    }

    private var sidePanel: some View {
        VStack(spacing: 18) {
            GameHUDView(
                difficulty: game.selectedDifficulty,
                score: game.currentScore,
                bestScore: game.bestScore,
                speedLabel: game.speedLabel,
                sessionState: game.sessionState,
                totalGames: game.recentStats.totalGames,
                onMenu: game.returnToMenu,
                onRestart: game.restartGame,
                onTogglePause: game.togglePause,
                canTogglePause: game.canTogglePause,
                compact: false
            )

            DirectionPadView(
                onUp: { game.turn(.up) },
                onLeft: { game.turn(.left) },
                onDown: { game.turn(.down) },
                onRight: { game.turn(.right) }
            )

            statsPanel
        }
    }

    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Session Stats")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            statRow(label: "Rounds", value: "\(game.recentStats.totalGames)")
            statRow(label: "Longest Snake", value: "\(game.recentStats.longestSnakeLength)")
            statRow(label: "Chill Best", value: "\(game.recentStats.bestScores[.chill])")
            statRow(label: "Classic Best", value: "\(game.recentStats.bestScores[.classic])")
            statRow(label: "Frenzy Best", value: "\(game.recentStats.bestScores[.frenzy])")
        }
        .padding(20)
        .background(panelBackground)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func statRow(label: String, value: String) -> some View {
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
