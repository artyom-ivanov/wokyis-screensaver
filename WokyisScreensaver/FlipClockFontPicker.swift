import SwiftUI

struct FlipClockFontPicker: View {
    @Binding var selection: FlipClockFont
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
    private var digitColor: Color {
        onLightBackground ? .black : .white
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(FlipClockFont.all) { font in
                Button {
                    selection = font
                } label: {
                    Text("8")
                        .font(.system(size: 18, weight: .semibold))
                        .fontDesign(font.design)
                        .foregroundStyle(digitColor)
                        .frame(width: 22, height: 22)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(font.id == selection.id ? selectedFill : unselectedFill)
                        )
                        .overlay(
                            Capsule()
                                .stroke(font.id == selection.id ? selectedStroke : Color.clear, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
