import SwiftUI

@Observable
final class Settings {
    var scale: Float = 2.30
    var lineCount: Float = 1.0
    var speed: Float = 0.046
    var thickness: Float = 1.12
    var softness: Float = 0.01
    var halo: Float = 0.0
    var haloBrightness: Float = 0.0
    var showPanel: Bool = true
}
