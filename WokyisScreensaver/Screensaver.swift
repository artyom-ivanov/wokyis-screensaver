import Foundation

enum ScreensaverID: String, CaseIterable, Identifiable {
    case noise = "noise"
    case gameOfLife = "game_of_life"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .noise:      return "Topographic"
        case .gameOfLife: return "Game of Life"
        }
    }
}
