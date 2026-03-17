import SwiftUI

struct GameBoardView: View {
    private let boardPadding: CGFloat = 18

    let snapshot: SnakeGameSnapshot
    let sessionState: GameSessionState
    let countdownValue: Int?
    let roundOutcome: GameRoundOutcome?
    let scoreDelta: Int?
    let onSwipe: (SnakeDirection) -> Void

    @State private var foodPulse = false
    @State private var floatingScoreText: String?
    @State private var floatingScoreOpacity = 0.0
    @State private var floatingScoreOffset: CGFloat = 0
    @State private var floatingScoreScale = 0.8
    @State private var boardFlashOpacity = 0.0
    @State private var countdownScale = 0.82

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let canvasSide = max(side - (boardPadding * 2), 0)
            let overlayMetrics = GameBoardMetrics(
                canvasSize: CGSize(width: canvasSide, height: canvasSide),
                boardSize: snapshot.boardSize
            )

            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                Canvas { context, canvasSize in
                    let metrics = GameBoardMetrics(canvasSize: canvasSize, boardSize: snapshot.boardSize)
                    context.fill(Path(metrics.boardRect), with: .color(Color(red: 0.06, green: 0.09, blue: 0.07)))

                    for row in 0..<snapshot.boardSize {
                        for col in 0..<snapshot.boardSize {
                            let rect = metrics
                                .rectForCell(column: col, row: row)
                                .insetBy(dx: 1, dy: 1)
                            let shade = (row + col).isMultiple(of: 2)
                            context.fill(
                                Path(roundedRect: rect, cornerRadius: metrics.cellSize * 0.18),
                                with: .color(shade ? Color(red: 0.11, green: 0.16, blue: 0.11) : Color(red: 0.09, green: 0.13, blue: 0.09))
                            )
                        }
                    }

                    for segment in snapshot.snake {
                        let rect = metrics
                            .rect(for: segment)
                            .insetBy(dx: metrics.cellSize * 0.08, dy: metrics.cellSize * 0.08)
                        let isHead = segment == snapshot.snake.first
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: metrics.cellSize * 0.28),
                            with: .linearGradient(
                                Gradient(colors: isHead ? [Color(red: 0.98, green: 0.86, blue: 0.28), Color(red: 0.92, green: 0.57, blue: 0.16)] : [snapshot.difficulty.snakePrimary, snapshot.difficulty.snakeSecondary]),
                                startPoint: CGPoint(x: rect.minX, y: rect.minY),
                                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                            )
                        )
                    }

                    if let food = snapshot.food {
                        let baseFoodRect = metrics
                            .rect(for: food)
                            .insetBy(dx: metrics.cellSize * 0.12, dy: metrics.cellSize * 0.12)
                        let foodRect = baseFoodRect.scaledAroundCenter(by: foodPulse ? 1.08 : 0.92)
                        context.addFilter(.shadow(color: Color(red: 1.0, green: 0.42, blue: 0.30).opacity(foodPulse ? 0.35 : 0.15), radius: foodPulse ? 10 : 4, x: 0, y: 0))
                        context.fill(
                            Path(ellipseIn: foodRect),
                            with: .radialGradient(
                                Gradient(colors: [Color(red: 1.0, green: 0.49, blue: 0.44), Color(red: 0.80, green: 0.14, blue: 0.18)]),
                                center: CGPoint(x: foodRect.midX, y: foodRect.midY),
                                startRadius: 2,
                                endRadius: metrics.cellSize * 0.5
                            )
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(boardPadding)

                if let floatingScoreText, sessionState == .running || sessionState == .gameOver {
                    Text(floatingScoreText)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(snapshot.difficulty.highlight.opacity(0.92), in: Capsule())
                        .position(
                            x: boardPadding + overlayMetrics.boardRect.midX,
                            y: boardPadding + overlayMetrics.boardRect.minY + (overlayMetrics.cellSize * 1.2)
                        )
                        .scaleEffect(floatingScoreScale)
                        .offset(y: floatingScoreOffset)
                        .opacity(floatingScoreOpacity)
                        .allowsHitTesting(false)
                }

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(flashColor.opacity(boardFlashOpacity))
                    .padding(boardPadding)
                    .blendMode(.screen)
                    .allowsHitTesting(false)

                overlay
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    handleSwipe(value.translation)
                }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                foodPulse = true
            }
        }
        .onChange(of: snapshot.score) { oldValue, newValue in
            guard newValue > oldValue else { return }
            triggerScoreBurst(delta: newValue - oldValue)
        }
        .onChange(of: sessionState) { _, newValue in
            guard newValue == .gameOver, let roundOutcome else { return }
            triggerBoardFlash(for: roundOutcome)
        }
        .onChange(of: countdownValue) { _, newValue in
            guard newValue != nil else { return }
            countdownScale = 0.72
            withAnimation(.spring(response: 0.28, dampingFraction: 0.54)) {
                countdownScale = 1.0
            }
        }
    }

    @ViewBuilder
    private var overlay: some View {
        switch sessionState {
        case .countdown:
            if let countdownValue {
                VStack(spacing: 10) {
                    Text("Starting In")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                    Text("\(countdownValue)")
                        .font(.system(size: 78, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .transition(.scale(scale: 0.55).combined(with: .opacity))
                        .scaleEffect(countdownScale)
                        .shadow(color: .white.opacity(0.28), radius: 16)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .animation(.spring(response: 0.3, dampingFraction: 0.72), value: countdownValue)
            }
        case .paused:
            VStack(spacing: 8) {
                Text("Paused")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                Text("Resume to continue the round.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        case .menu, .running, .gameOver:
            EmptyView()
        }
    }

    private func handleSwipe(_ translation: CGSize) {
        if abs(translation.width) > abs(translation.height) {
            onSwipe(translation.width > 0 ? .right : .left)
        } else {
            onSwipe(translation.height > 0 ? .down : .up)
        }
    }

    private var flashColor: Color {
        switch roundOutcome {
        case .victory:
            return Color(red: 1.0, green: 0.85, blue: 0.26)
        case .crash, .none:
            return Color(red: 1.0, green: 0.30, blue: 0.24)
        }
    }

    private func triggerScoreBurst(delta: Int) {
        let amount = scoreDelta ?? delta
        floatingScoreText = "+\(amount)"
        floatingScoreOpacity = 1
        floatingScoreScale = 0.72
        floatingScoreOffset = 12

        withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) {
            floatingScoreScale = 1.0
            floatingScoreOffset = -12
        }

        withAnimation(.easeOut(duration: 0.42).delay(0.22)) {
            floatingScoreOpacity = 0
            floatingScoreOffset = -28
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            floatingScoreText = nil
        }
    }

    private func triggerBoardFlash(for outcome: GameRoundOutcome) {
        boardFlashOpacity = outcome == .victory ? 0.88 : 0.78
        withAnimation(.easeOut(duration: outcome == .victory ? 0.65 : 0.36)) {
            boardFlashOpacity = 0.0
        }
    }
}

struct GameBoardMetrics {
    let boardRect: CGRect
    let cellSize: CGFloat

    init(canvasSize: CGSize, boardSize: Int) {
        let side = min(canvasSize.width, canvasSize.height)
        let origin = CGPoint(
            x: (canvasSize.width - side) / 2,
            y: (canvasSize.height - side) / 2
        )
        self.boardRect = CGRect(origin: origin, size: CGSize(width: side, height: side))
        self.cellSize = side / CGFloat(boardSize)
    }

    func rectForCell(column: Int, row: Int) -> CGRect {
        CGRect(
            x: boardRect.minX + (CGFloat(column) * cellSize),
            y: boardRect.minY + (CGFloat(row) * cellSize),
            width: cellSize,
            height: cellSize
        )
    }

    func rect(for point: SnakePoint) -> CGRect {
        rectForCell(column: point.x, row: point.y)
    }
}

private extension CGRect {
    func scaledAroundCenter(by scale: CGFloat) -> CGRect {
        let width = self.width * scale
        let height = self.height * scale
        return CGRect(
            x: midX - (width / 2),
            y: midY - (height / 2),
            width: width,
            height: height
        )
    }
}
