import SwiftUI
import UIKit

struct KeyboardInputView: UIViewRepresentable {
    let onDirection: (SnakeDirection) -> Void

    func makeUIView(context: Context) -> KeyboardCaptureView {
        let view = KeyboardCaptureView()
        view.onDirection = onDirection
        return view
    }

    func updateUIView(_ uiView: KeyboardCaptureView, context: Context) {
        uiView.onDirection = onDirection
        DispatchQueue.main.async {
            uiView.becomeFirstResponderIfNeeded()
        }
    }
}

final class KeyboardCaptureView: UIView {
    var onDirection: ((SnakeDirection) -> Void)?

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        becomeFirstResponderIfNeeded()
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            command(input: UIKeyCommand.inputUpArrow, direction: .up),
            command(input: UIKeyCommand.inputDownArrow, direction: .down),
            command(input: UIKeyCommand.inputLeftArrow, direction: .left),
            command(input: UIKeyCommand.inputRightArrow, direction: .right),
            command(input: "w", direction: .up),
            command(input: "a", direction: .left),
            command(input: "s", direction: .down),
            command(input: "d", direction: .right),
            command(input: "W", direction: .up),
            command(input: "A", direction: .left),
            command(input: "S", direction: .down),
            command(input: "D", direction: .right)
        ]
    }

    func becomeFirstResponderIfNeeded() {
        guard window != nil, !isFirstResponder else { return }
        becomeFirstResponder()
    }

    private func command(input: String, direction: SnakeDirection) -> UIKeyCommand {
        let selector: Selector
        switch direction {
        case .up: selector = #selector(handleUp)
        case .down: selector = #selector(handleDown)
        case .left: selector = #selector(handleLeft)
        case .right: selector = #selector(handleRight)
        }
        return UIKeyCommand(title: "", action: selector, input: input, modifierFlags: [])
    }

    @objc private func handleUp() {
        onDirection?(.up)
    }

    @objc private func handleDown() {
        onDirection?(.down)
    }

    @objc private func handleLeft() {
        onDirection?(.left)
    }

    @objc private func handleRight() {
        onDirection?(.right)
    }
}
