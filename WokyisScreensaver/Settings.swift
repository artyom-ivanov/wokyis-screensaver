import SwiftUI

@Observable
final class Settings {
    var scale: Float = 2.5
    var lineCount: Float = 8.0
    var speed: Float = 0.10
    var thickness: Float = 1.0
    var softness: Float = 1.5
    var halo: Float = 2.0
    var haloBrightness: Float = 0.42
    var showPanel: Bool = true
}
