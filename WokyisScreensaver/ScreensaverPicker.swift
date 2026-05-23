import SwiftUI

struct ScreensaverPicker: View {
    @Binding var selection: ScreensaverID

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
                        .foregroundStyle(selection == id ? Color.black : Color.white)
                        .background(
                            Capsule()
                                .fill(selection == id ? Color.white : Color.white.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
