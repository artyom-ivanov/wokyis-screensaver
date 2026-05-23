import SwiftUI

struct FlipClockView: View {
    var body: some View {
        GeometryReader { proxy in
            let size = tileSize(for: proxy.size)
            ZStack {
                Color.black
                HStack(spacing: size * 0.08) {
                    pair(tens: 1, units: 2, size: size)
                    colonSeparator(size: size)
                    pair(tens: 3, units: 4, size: size)
                    colonSeparator(size: size)
                    pair(tens: 5, units: 6, size: size)
                }
            }
        }
        .ignoresSafeArea()
    }

    // Six tiles + two colon gaps must fit horizontally with margin.
    // Tile width ≈ size * 0.72, so total ≈ 6*0.72*size + 2*gap*size.
    // Pick size from the smaller of (width budget) and (height budget).
    private func tileSize(for container: CGSize) -> CGFloat {
        let widthBudget = container.width * 0.92
        let heightBudget = container.height * 0.65
        let widthDriven = widthBudget / (6 * 0.72 + 2 * 0.6)   // colons take ~0.6 * size
        let heightDriven = heightBudget / 1.10
        return min(widthDriven, heightDriven)
    }

    private func pair(tens: Int, units: Int, size: CGFloat) -> some View {
        HStack(spacing: size * 0.04) {
            FlipTile(digit: tens, size: size)
            FlipTile(digit: units, size: size)
        }
    }

    private func colonSeparator(size: CGFloat) -> some View {
        VStack(spacing: size * 0.30) {
            Circle().frame(width: size * 0.10, height: size * 0.10)
            Circle().frame(width: size * 0.10, height: size * 0.10)
        }
        .foregroundStyle(Color(white: 0.45))
        .frame(width: size * 0.6, height: size * 1.10)
    }
}

#Preview {
    FlipClockView()
        .frame(width: 1200, height: 600)
}
