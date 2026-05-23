import SwiftUI

struct FlipClockThemePicker: View {
    @Binding var selection: FlipClockTheme
    var onLightBackground: Bool = false

    private var selectedFill: Color {
        onLightBackground ? Color.black.opacity(0.18) : Color.white.opacity(0.22)
    }
    private var unselectedFill: Color {
        onLightBackground ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
    }
    private var selectedStroke: Color {
        onLightBackground ? .black : .white
    }
    private var swatchStroke: Color {
        onLightBackground ? Color.black.opacity(0.15) : Color.white.opacity(0.15)
    }

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
                                .fill(theme.id == selection.id ? selectedFill : unselectedFill)
                        )
                        .overlay(
                            Capsule()
                                .stroke(theme.id == selection.id ? selectedStroke : Color.clear, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func swatch(for theme: FlipClockTheme) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(theme.tile)
            .frame(width: 22, height: 18)
            .overlay(
                Text("8")
                    .font(.system(size: 12, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(theme.digit)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(swatchStroke, lineWidth: 0.5)
            )
    }
}
