import SwiftUI

struct GameBoardView: View {
    let snapshot: SnakeGameSnapshot
    let sessionState: GameSessionState
    let countdownValue: Int?
    let onSwipe: (SnakeDirection) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let cell = size / CGFloat(snapshot.boardSize)

            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                Canvas { context, canvasSize in
                    let playable = CGRect(origin: .zero, size: canvasSize)
                    context.fill(Path(playable), with: .color(Color(red: 0.06, green: 0.09, blue: 0.07)))

                    for row in 0..<snapshot.boardSize {
                        for col in 0..<snapshot.boardSize {
                            let rect = CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell).insetBy(dx: 1, dy: 1)
                            let shade = (row + col).isMultiple(of: 2)
                            context.fill(
                                Path(roundedRect: rect, cornerRadius: cell * 0.18),
                                with: .color(shade ? Color(red: 0.11, green: 0.16, blue: 0.11) : Color(red: 0.09, green: 0.13, blue: 0.09))
                            )
                        }
                    }

                    for segment in snapshot.snake {
                        let rect = CGRect(x: CGFloat(segment.x) * cell, y: CGFloat(segment.y) * cell, width: cell, height: cell).insetBy(dx: cell * 0.08, dy: cell * 0.08)
                        let isHead = segment == snapshot.snake.first
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: cell * 0.28),
                            with: .linearGradient(
                                Gradient(colors: isHead ? [Color(red: 0.98, green: 0.86, blue: 0.28), Color(red: 0.92, green: 0.57, blue: 0.16)] : [snapshot.difficulty.snakePrimary, snapshot.difficulty.snakeSecondary]),
                                startPoint: CGPoint(x: rect.minX, y: rect.minY),
                                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                            )
                        )
                    }

                    let foodRect = CGRect(x: CGFloat(snapshot.food.x) * cell, y: CGFloat(snapshot.food.y) * cell, width: cell, height: cell).insetBy(dx: cell * 0.12, dy: cell * 0.12)
                    context.fill(
                        Path(ellipseIn: foodRect),
                        with: .radialGradient(
                            Gradient(colors: [Color(red: 1.0, green: 0.49, blue: 0.44), Color(red: 0.80, green: 0.14, blue: 0.18)]),
                            center: CGPoint(x: foodRect.midX, y: foodRect.midY),
                            startRadius: 2,
                            endRadius: cell * 0.5
                        )
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(18)

                overlay
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    handleSwipe(value.translation)
                }
        )
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
}
