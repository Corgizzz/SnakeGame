import SwiftUI

struct MainMenuView: View {
    @Binding var selectedDifficulty: GameDifficulty
    @ObservedObject var settingsStore: GameSettingsStore
    let stats: GameStatsSnapshot
    let isRegular: Bool
    let onStart: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: isRegular ? 28 : 22) {
                titleBlock
                    .padding(.top, isRegular ? 32 : 12)

                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(Color.black.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )

                    VStack(spacing: 16) {
                        Text("Choose Difficulty")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        difficultyCards
                        settingsCard
                        statsCard

                        Button(action: onStart) {
                            Label("Start Game", systemImage: "play.fill")
                                .font(.system(size: isRegular ? 20 : 18, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.96, green: 0.50, blue: 0.22), Color(red: 0.88, green: 0.28, blue: 0.18)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)
                    }
                    .padding(isRegular ? 28 : 20)
                }
                .frame(maxWidth: 980)

                previewBoard
                    .frame(maxWidth: 980)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 14) {
            Text("Snake Arcade")
                .font(.system(size: isRegular ? 56 : 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Universal iPhone and iPad snake with swipe controls, keyboard support, sound, haptics, and a cleaner game loop.")
                .font(.system(size: isRegular ? 18 : 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 720)
        }
    }

    private var difficultyCards: some View {
        let columns = [GridItem(.adaptive(minimum: isRegular ? 220 : 160), spacing: 14)]

        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(GameDifficulty.allCases) { difficulty in
                Button {
                    selectedDifficulty = difficulty
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(difficulty.title)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Spacer(minLength: 8)
                            Text(difficulty.speedSummary)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.12), in: Capsule())
                        }

                        Text(difficulty.subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.leading)

                        Text(difficulty.tip)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 0.97, green: 0.82, blue: 0.32))

                        Spacer(minLength: 0)

                        Text("Best \(stats.bestScores[difficulty])")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .foregroundStyle(.white)
                    .padding(18)
                    .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(selectedDifficulty == difficulty ? difficulty.highlight.opacity(0.42) : Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(selectedDifficulty == difficulty ? difficulty.highlight : Color.white.opacity(0.08), lineWidth: selectedDifficulty == difficulty ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var settingsCard: some View {
        VStack(spacing: 12) {
            toggleRow(title: "Sound Effects", subtitle: "Play tones on countdown complete, food pickup, and crash.", isOn: $settingsStore.soundEnabled)
            toggleRow(title: "Haptics", subtitle: "Use impact feedback for start, growth, and game over.", isOn: $settingsStore.hapticsEnabled)
        }
        .padding(18)
        .background(cardBackground)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Arcade Stats")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack {
                statBlock(title: "Rounds", value: "\(stats.totalGames)")
                statBlock(title: "Longest", value: "\(stats.longestSnakeLength)")
            }

            if stats.recentRounds.isEmpty {
                Text("No rounds yet. Start one and the recent scores will appear here.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
            } else {
                ForEach(stats.recentRounds.prefix(3)) { round in
                    HStack {
                        Text(round.difficulty.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(round.difficulty.highlight)
                        Spacer()
                        Text("Score \(round.score)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Len \(round.snakeLength)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                }
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private var previewBoard: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("How It Plays")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Swipe anywhere on the board, use the D-pad, or play on iPad with arrow keys and WASD. Rounds resume through a countdown after interruptions.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.14))
                .frame(width: isRegular ? 240 : 140, height: isRegular ? 140 : 110)
                .overlay {
                    PreviewPattern()
                        .padding(16)
                }
        }
        .padding(isRegular ? 24 : 18)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer(minLength: 8)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(red: 0.29, green: 0.83, blue: 0.45))
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct PreviewPattern: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let cell = min(width, height) / 5

            Canvas { context, _ in
                let segments = [
                    CGRect(x: cell * 0.8, y: cell * 1.8, width: cell, height: cell),
                    CGRect(x: cell * 1.8, y: cell * 1.8, width: cell, height: cell),
                    CGRect(x: cell * 2.8, y: cell * 1.8, width: cell, height: cell),
                    CGRect(x: cell * 2.8, y: cell * 0.8, width: cell, height: cell)
                ]

                for (index, rect) in segments.enumerated() {
                    let inset = rect.insetBy(dx: 3, dy: 3)
                    let colors: [Color] = index == segments.count - 1
                        ? [Color(red: 0.98, green: 0.86, blue: 0.28), Color(red: 0.92, green: 0.57, blue: 0.16)]
                        : [Color(red: 0.31, green: 0.91, blue: 0.55), Color(red: 0.12, green: 0.64, blue: 0.34)]
                    context.fill(
                        Path(roundedRect: inset, cornerRadius: cell * 0.24),
                        with: .linearGradient(
                            Gradient(colors: colors),
                            startPoint: CGPoint(x: inset.minX, y: inset.minY),
                            endPoint: CGPoint(x: inset.maxX, y: inset.maxY)
                        )
                    )
                }

                let apple = CGRect(x: cell * 3.6, y: cell * 3.0, width: cell * 0.9, height: cell * 0.9)
                context.fill(
                    Path(ellipseIn: apple),
                    with: .radialGradient(
                        Gradient(colors: [Color(red: 1.0, green: 0.49, blue: 0.44), Color(red: 0.80, green: 0.14, blue: 0.18)]),
                        center: CGPoint(x: apple.midX, y: apple.midY),
                        startRadius: 2,
                        endRadius: cell * 0.5
                    )
                )
            }
        }
    }
}
