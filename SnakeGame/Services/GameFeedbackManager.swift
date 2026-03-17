import AVFoundation
import UIKit

enum GameEvent {
    case roundStarted
    case foodEaten
    case gameOver
    case victory
}

@MainActor
protocol GameFeedbackProviding: AnyObject {
    func handle(_ event: GameEvent, soundEnabled: Bool, hapticsEnabled: Bool)
}

@MainActor
final class GameFeedbackManager: NSObject, GameFeedbackProviding {
    private enum SoundEffect: String, CaseIterable {
        case start
        case eat
        case crash
    }

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private let session = AVAudioSession.sharedInstance()
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    override init() {
        super.init()
        prepareAudioSession()
        preparePlayers()
        observeInterruptions()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func handle(_ event: GameEvent, soundEnabled: Bool, hapticsEnabled: Bool) {
        if soundEnabled {
            switch event {
            case .roundStarted: play(.start)
            case .foodEaten: play(.eat)
            case .gameOver: play(.crash)
            case .victory: play(.start)
            }
        }

        guard hapticsEnabled else { return }
        switch event {
        case .roundStarted:
            mediumImpact.prepare()
            mediumImpact.impactOccurred(intensity: 0.9)
        case .foodEaten:
            lightImpact.prepare()
            lightImpact.impactOccurred(intensity: 0.8)
        case .gameOver:
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.error)
        case .victory:
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.success)
        }
    }

    private func prepareAudioSession() {
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }

        if type == .ended {
            try? session.setActive(true)
            players.values.forEach { $0.prepareToPlay() }
        }
    }

    private func preparePlayers() {
        for effect in SoundEffect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else {
                continue
            }
            player.prepareToPlay()
            players[effect] = player
        }
    }

    private func play(_ effect: SoundEffect) {
        guard let player = players[effect] else { return }
        player.currentTime = 0
        player.play()
    }
}
