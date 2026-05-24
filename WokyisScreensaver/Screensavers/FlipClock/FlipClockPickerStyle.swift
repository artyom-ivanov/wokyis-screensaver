import SwiftUI

/// Shared colour palette for the flip-clock hover pickers (Theme / Font /
/// Seconds). Switches between dark-on-light and light-on-dark based on the
/// active flip-clock background.
struct FlipClockPickerStyle {
    let onLightBackground: Bool

    var selectedFill: Color {
        onLightBackground ? Color.black.opacity(0.18) : Color.white.opacity(0.22)
    }

    var unselectedFill: Color {
        onLightBackground ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
    }

    var selectedStroke: Color {
        onLightBackground ? .black : .white
    }

    /// Text / glyph colour for content rendered inside the pills.
    var foreground: Color {
        onLightBackground ? .black : .white
    }

    /// Hairline stroke for the theme-swatch circle.
    var swatchStroke: Color {
        onLightBackground ? Color.black.opacity(0.25) : Color.white.opacity(0.25)
    }
}
