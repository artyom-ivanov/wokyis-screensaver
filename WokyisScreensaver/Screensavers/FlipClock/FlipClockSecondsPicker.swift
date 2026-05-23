import SwiftUI

struct FlipClockSecondsPicker: View {
    @Binding var showSeconds: Bool
    var onLightBackground: Bool = false

    private var style: FlipClockPickerStyle { .init(onLightBackground: onLightBackground) }

    var body: some View {
        HStack(spacing: 8) {
            pill(label: "12:34", isSelected: !showSeconds) { showSeconds = false }
            pill(label: "12:34:56", isSelected: showSeconds) { showSeconds = true }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func pill(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(style.foreground)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? style.selectedFill : style.unselectedFill)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? style.selectedStroke : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}
