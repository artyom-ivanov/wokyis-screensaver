import SwiftUI

struct CalendarTheme: Identifiable, Equatable {
    let id: String
    let background: Color
    let cardFill: Color
    let primaryText: Color
    let secondaryText: Color
    let timeIndicator: Color
    let cardBorder: Color
    let dashedBorder: Color

    static let dark = CalendarTheme(
        id: "dark",
        background: Color(red: 0.04, green: 0.04, blue: 0.04),
        cardFill: Color(red: 0.11, green: 0.11, blue: 0.11),
        primaryText: .white,
        secondaryText: Color(white: 0.55),
        timeIndicator: .white,
        cardBorder: Color(white: 0.35),
        dashedBorder: Color(white: 0.25)
    )

    static let light = CalendarTheme(
        id: "light",
        background: Color(white: 0.96),
        cardFill: .white,
        primaryText: .black,
        secondaryText: Color(white: 0.43),
        timeIndicator: .black,
        cardBorder: Color(white: 0.70),
        dashedBorder: Color(white: 0.75)
    )

    static let all: [CalendarTheme] = [.dark, .light]
    static let `default`: CalendarTheme = .dark

    static func by(id: String) -> CalendarTheme {
        all.first(where: { $0.id == id }) ?? .default
    }
}
