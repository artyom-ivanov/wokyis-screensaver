import SwiftUI

struct FlipClockTheme: Identifiable, Equatable {
    let id: String
    let background: Color
    let tile: Color
    let digit: Color
    let colon: Color
    let ampm: Color
    let tileShadow: Color
    let tileShadowOpacity: Double

    static let dark = FlipClockTheme(
        id: "dark",
        background: .black,
        tile: Color(white: 0.18),
        digit: Color(white: 0.92),
        colon: Color(white: 0.45),
        ampm: Color(white: 0.55),
        tileShadow: .black,
        tileShadowOpacity: 0.35
    )

    static let light = FlipClockTheme(
        id: "light",
        background: Color(white: 0.93),
        tile: .white,
        digit: Color(white: 0.18),
        colon: Color(white: 0.50),
        ampm: Color(white: 0.45),
        tileShadow: .black,
        tileShadowOpacity: 0.12
    )

    static let all: [FlipClockTheme] = [.dark, .light]
    static let `default`: FlipClockTheme = .dark

    static func by(id: String) -> FlipClockTheme {
        all.first(where: { $0.id == id }) ?? .default
    }
}
