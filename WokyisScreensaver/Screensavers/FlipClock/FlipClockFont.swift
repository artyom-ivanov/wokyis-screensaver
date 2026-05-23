import SwiftUI

struct FlipClockFont: Identifiable, Equatable {
    let id: String
    let displayName: String
    let design: Font.Design

    static let rounded = FlipClockFont(id: "rounded", displayName: "Rounded", design: .rounded)
    static let sans    = FlipClockFont(id: "sans",    displayName: "Sans",    design: .default)
    static let serif   = FlipClockFont(id: "serif",   displayName: "Serif",   design: .serif)

    static let all: [FlipClockFont] = [.rounded, .sans, .serif]
    static let `default`: FlipClockFont = .rounded

    static func by(id: String) -> FlipClockFont {
        all.first(where: { $0.id == id }) ?? .default
    }
}
