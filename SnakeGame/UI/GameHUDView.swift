import SwiftUI

struct GameHUDView: View {
    let difficulty: GameDifficulty
    let score: Int
    let bestScore: Int
    let speedLabel: String
    let sessionState: GameSessionState
    let totalGames: Int
    let onMenu: () -> Void
    let onRestart: () -> Void
    let onTogglePause: () -> Void
    let canTogglePause: Bool
    let compact: Bool

    var body: some View {
        VStack(spacing: compact ? 14 : 18) {
            header
            scoreGrid
            actionRow
        }
        .padding(compact ? 18 : 20)
        .background(cardBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(difficulty.title)
                .font(.system(size: compact ? 16 : 18, weight: .bold, design: .rounded))
                .foregroundStyle(difficulty.highlight)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Snake")
                .font(.system(size: compact ? 34 : 40, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(statusCopy)
                .font(.system(size: compact ? 13 : 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var scoreGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 12) {
            statCard(title: "Score", value: "\(score)")
            statCard(title: "Best", value: "\(bestScore)")
            statCard(title: "Speed", value: speedLabel)
            statCard(title: "Rounds", value: "\(totalGames)")
        }
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(action: onMenu) {
                    buttonLabel("Menu", systemImage: "house")
                }
                .buttonStyle(.plain)

                Button(action: onRestart) {
                    buttonLabel("Restart", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }

            Button(action: onTogglePause) {
                Label(sessionState == .paused ? "Resume" : "Pause", systemImage: sessionState == .paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(canTogglePause ? difficulty.highlight.opacity(0.88) : Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .foregroundStyle(canTogglePause ? .black.opacity(0.78) : .white.opacity(0.5))
            .disabled(!canTogglePause)
        }
        .foregroundStyle(.white)
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
            Text(value)
                .font(.system(size: compact ? 23 : 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func buttonLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusCopy: String {
        switch sessionState {
        case .menu: "Ready to queue a new round."
        case .countdown: "Countdown is running. Input unlocks when the round starts."
        case .running: "Swipe, tap the D-pad, or use arrow keys and WASD."
        case .paused: "The round is paused and can resume through a countdown."
        case .gameOver: "Round complete. Review the result and start again."
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}
