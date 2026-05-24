import SwiftUI

struct FlipClockThemePicker: View {
    @Binding var selection: FlipClockTheme
    var onLightBackground: Bool = false

    private var style: FlipClockPickerStyle { .init(onLightBackground: onLightBackground) }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(FlipClockTheme.all) { theme in
                Button {
                    selection = theme
                } label: {
                    swatch(for: theme)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(theme.id == selection.id ? style.selectedFill : style.unselectedFill)
                        )
                        .overlay(
                            Capsule()
                                .stroke(theme.id == selection.id ? style.selectedStroke : Color.clear, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func swatch(for theme: FlipClockTheme) -> some View {
        Circle()
            .fill(theme.tile)
            .frame(width: 18, height: 18)
            .overlay(Circle().stroke(style.swatchStroke, lineWidth: 0.5))
    }
}
