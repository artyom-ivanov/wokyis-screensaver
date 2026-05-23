import SwiftUI
import simd

struct Palette: Identifiable, Equatable {
    let id: String
    let colorA: SIMD3<Float>
    let colorB: SIMD3<Float>

    var swiftColorA: Color {
        Color(red: Double(colorA.x), green: Double(colorA.y), blue: Double(colorA.z))
    }
    var swiftColorB: Color {
        Color(red: Double(colorB.x), green: Double(colorB.y), blue: Double(colorB.z))
    }

    static let all: [Palette] = [
        Palette(id: "orange_blue",
                colorA: rgb(0xFF, 0x5E, 0x16),
                colorB: rgb(0x1E, 0x55, 0xFF)),
        Palette(id: "cyan_pink",
                colorA: rgb(0x00, 0xC5, 0xFF),
                colorB: rgb(0xFF, 0x1A, 0x86)),
        Palette(id: "yellow_lav",
                colorA: rgb(0xFF, 0xDF, 0x4A),
                colorB: rgb(0xD0, 0x92, 0xFF)),
        Palette(id: "spring_lav",
                colorA: rgb(0x10, 0xE2, 0x5C),
                colorB: rgb(0xD0, 0x92, 0xFF)),
        Palette(id: "mono",
                colorA: rgb(0xF0, 0xF0, 0xF0),
                colorB: rgb(0x70, 0x70, 0x70)),
    ]

    static let `default`: Palette = all[0]

    static func by(id: String) -> Palette {
        all.first(where: { $0.id == id }) ?? .default
    }
}

private func rgb(_ r: Int, _ g: Int, _ b: Int) -> SIMD3<Float> {
    SIMD3<Float>(Float(r) / 255, Float(g) / 255, Float(b) / 255)
}
