import SwiftUI

struct FlipClockThemePicker: View {
    @Binding var selection: FlipClockTheme

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
                                .fill(theme.id == selection.id ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
                        )
                        .overlay(
                            Capsule()
                                .stroke(theme.id == selection.id ? Color.white : Color.clear, lineWidth: 1.5)
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
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }
}
