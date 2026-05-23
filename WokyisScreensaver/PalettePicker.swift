import SwiftUI

struct PalettePicker: View {
    @Binding var selection: Palette

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Palette.all) { palette in
                Button {
                    selection = palette
                } label: {
                    HStack(spacing: 4) {
                        Circle().fill(palette.swiftColorA).frame(width: 14, height: 14)
                        Circle().fill(palette.swiftColorB).frame(width: 14, height: 14)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(palette.id == selection.id ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .stroke(palette.id == selection.id ? Color.white : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
