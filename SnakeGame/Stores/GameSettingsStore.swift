import Combine
import Foundation

@MainActor
final class GameSettingsStore: ObservableObject {
    private enum Storage {
        static let soundEnabledKey = "snake.soundEnabled"
        static let hapticsEnabledKey = "snake.hapticsEnabled"
    }

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Storage.soundEnabledKey) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Storage.hapticsEnabledKey) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Storage.soundEnabledKey) == nil {
            defaults.set(true, forKey: Storage.soundEnabledKey)
        }
        if defaults.object(forKey: Storage.hapticsEnabledKey) == nil {
            defaults.set(true, forKey: Storage.hapticsEnabledKey)
        }
        soundEnabled = defaults.bool(forKey: Storage.soundEnabledKey)
        hapticsEnabled = defaults.bool(forKey: Storage.hapticsEnabledKey)
    }
}
