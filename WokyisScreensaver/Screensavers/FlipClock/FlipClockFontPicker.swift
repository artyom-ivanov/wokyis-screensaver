import SwiftUI

struct FlipClockFontPicker: View {
    @Binding var selection: FlipClockFont
    var onLightBackground: Bool = false

    private var style: FlipClockPickerStyle { .init(onLightBackground: onLightBackground) }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(FlipClockFont.all) { font in
                Button {
                    selection = font
                } label: {
                    Text("1")
                        .font(.system(size: 18, weight: .semibold))
                        .fontDesign(font.design)
                        .foregroundStyle(style.foreground)
                        .frame(width: 22, height: 22)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(font.id == selection.id ? style.selectedFill : style.unselectedFill)
                        )
                        .overlay(
                            Capsule()
                                .stroke(font.id == selection.id ? style.selectedStroke : Color.clear, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
