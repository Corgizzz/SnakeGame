import SwiftUI

extension GameDifficulty {
    var highlight: Color {
        switch self {
        case .chill: Color(red: 0.44, green: 0.84, blue: 0.92)
        case .classic: Color(red: 0.30, green: 0.86, blue: 0.46)
        case .frenzy: Color(red: 0.98, green: 0.64, blue: 0.24)
        }
    }

    var snakePrimary: Color {
        switch self {
        case .chill: Color(red: 0.44, green: 0.86, blue: 0.95)
        case .classic: Color(red: 0.31, green: 0.91, blue: 0.55)
        case .frenzy: Color(red: 0.98, green: 0.74, blue: 0.22)
        }
    }

    var snakeSecondary: Color {
        switch self {
        case .chill: Color(red: 0.16, green: 0.63, blue: 0.79)
        case .classic: Color(red: 0.12, green: 0.64, blue: 0.34)
        case .frenzy: Color(red: 0.91, green: 0.42, blue: 0.14)
        }
    }
}
