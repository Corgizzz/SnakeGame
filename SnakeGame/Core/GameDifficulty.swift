import Foundation

enum GameDifficulty: String, CaseIterable, Identifiable, Codable {
    case chill
    case classic
    case frenzy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chill: "Chill"
        case .classic: "Classic"
        case .frenzy: "Frenzy"
        }
    }

    var subtitle: String {
        switch self {
        case .chill: "Lower starting speed with gentle acceleration. Good for phones and first runs."
        case .classic: "Balanced speed curve with readable turns. This is the default arcade feel."
        case .frenzy: "Fast opening pace and sharper acceleration. Built for short, high-pressure runs."
        }
    }

    var tip: String {
        switch self {
        case .chill: "Best for relaxed touch controls"
        case .classic: "Best all-around mode"
        case .frenzy: "Only if you trust your reactions"
        }
    }

    var speedSummary: String {
        switch self {
        case .chill: "Slow"
        case .classic: "Medium"
        case .frenzy: "Fast"
        }
    }

    var baseTick: TimeInterval {
        switch self {
        case .chill: 0.27
        case .classic: 0.21
        case .frenzy: 0.15
        }
    }

    var minimumTick: TimeInterval {
        switch self {
        case .chill: 0.12
        case .classic: 0.09
        case .frenzy: 0.06
        }
    }

    var accelerationPerFood: TimeInterval {
        switch self {
        case .chill: 0.006
        case .classic: 0.008
        case .frenzy: 0.010
        }
    }
}
