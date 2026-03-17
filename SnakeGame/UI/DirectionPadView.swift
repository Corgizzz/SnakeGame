import SwiftUI

struct DirectionPadView: View {
    let onUp: () -> Void
    let onLeft: () -> Void
    let onDown: () -> Void
    let onRight: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Controls")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                controlButton(systemName: "arrow.up", action: onUp)
                HStack(spacing: 12) {
                    controlButton(systemName: "arrow.left", action: onLeft)
                    controlButton(systemName: "arrow.down", action: onDown)
                    controlButton(systemName: "arrow.right", action: onRight)
                }
            }

            Text("Swipe anywhere on the board for fast turns.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(cardBackground)
    }

    private func controlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .bold))
                .frame(width: 72, height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
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
