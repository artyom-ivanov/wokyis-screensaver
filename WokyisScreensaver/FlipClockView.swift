import SwiftUI

struct FlipClockView: View {
    var body: some View {
        ZStack {
            Color.black
            Text("flip clock — placeholder")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
        }
    }
}

#Preview {
    FlipClockView()
        .frame(width: 800, height: 500)
}
