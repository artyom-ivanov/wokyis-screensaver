import SwiftUI

struct CalendarThemePicker: View {
    @Binding var selection: CalendarTheme
    var onLightBackground: Bool = false

    private var selectedFill: Color {
        onLightBackground ? Color.black.opacity(0.18) : Color.white.opacity(0.22)
    }
    private var unselectedFill: Color {
        onLightBackground ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
    }
    private var selectedStroke: Color { onLightBackground ? .black : .white }
    private var swatchStroke: Color {
        onLightBackground ? Color.black.opacity(0.25) : Color.white.opacity(0.25)
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(CalendarTheme.all) { theme in
                Button {
                    selection = theme
                } label: {
                    Circle()
                        .fill(theme.cardFill)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(swatchStroke, lineWidth: 0.5))
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
}
