import SwiftUI

struct GameOverOverlayView: View {
    let summary: GameRoundSummary
    let recentStats: GameStatsSnapshot
    let onRestart: () -> Void
    let onMenu: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Game Over")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text(summary.isNewRecord ? "New \(summary.difficulty.title) record" : "Round complete")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(summary.difficulty.highlight)
                Text("Score \(summary.score) • Best \(summary.bestScore) • Snake \(summary.longestSnakeLength)")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                Text("Global longest \(recentStats.longestSnakeLength) • Total rounds \(recentStats.totalGames)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button(action: onRestart) {
                    Text("Play Again")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.95, green: 0.46, blue: 0.23), in: Capsule())
                }

                Button(action: onMenu) {
                    Text("Menu")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.14), in: Capsule())
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(24)
    }
}
