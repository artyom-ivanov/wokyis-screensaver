import Foundation

enum ScreensaverID: String, CaseIterable, Identifiable {
    case noise = "noise"
    case gameOfLife = "game_of_life"
    case flipClock = "flip_clock"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .noise:      return "Topographic"
        case .gameOfLife: return "Game of Life"
        case .flipClock:  return "Flip Clock"
        }
    }
}
