import SwiftUI

struct FlipClockSecondsPicker: View {
    @Binding var showSeconds: Bool
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
    private var textColor: Color {
        onLightBackground ? .black : .white
    }

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
                .foregroundStyle(textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? selectedFill : unselectedFill)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? selectedStroke : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}
