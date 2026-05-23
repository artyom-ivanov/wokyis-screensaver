import SwiftUI

struct ScreensaverPicker: View {
    @Binding var selection: ScreensaverID
    var onLightBackground: Bool = false

    private var selectedFill: Color { onLightBackground ? .black : .white }
    private var selectedText: Color { onLightBackground ? .white : .black }
    private var unselectedFill: Color {
        onLightBackground ? Color.black.opacity(0.10) : Color.white.opacity(0.12)
    }
    private var unselectedText: Color { onLightBackground ? .black : .white }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ScreensaverID.allCases) { id in
                Button {
                    selection = id
                } label: {
                    Text(id.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(selection == id ? selectedText : unselectedText)
                        .background(
                            Capsule()
                                .fill(selection == id ? selectedFill : unselectedFill)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
