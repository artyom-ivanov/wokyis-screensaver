import SwiftUI

/// A single-digit flip-clock tile. Two stacked rounded half-cards
/// (large outer corners, small inner corners) with a thin gap between
/// them — the gap is the "split line".
///
/// Static placeholder for now; flip animation is added in a later step.
struct FlipTile: View {
    let digit: Int
    let size: CGFloat   // controls font + frame; everything else scales off this

    private var width: CGFloat { size * 0.72 }
    private var height: CGFloat { size * 1.10 }
    private var gap: CGFloat { max(2, size * 0.012) }
    private var halfHeight: CGFloat { (height - gap) / 2 }
    private var radiusLarge: CGFloat { size * 0.08 }
    private var radiusSmall: CGFloat { size * 0.015 }

    private let tileColor = Color(white: 0.18)
    private let digitColor = Color(white: 0.92)

    var body: some View {
        VStack(spacing: gap) {
            halfCard(alignment: .top)
            halfCard(alignment: .bottom)
        }
        .frame(width: width, height: height)
    }

    private func halfCard(alignment: Alignment) -> some View {
        ZStack(alignment: alignment) {
            cardShape(alignment: alignment)
                .fill(tileColor)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                .frame(height: halfHeight)

            Text("\(digit)")
                .font(.system(size: size, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundStyle(digitColor)
                .frame(width: width, height: height)
                .mask(alignment: alignment) {
                    Rectangle().frame(height: halfHeight)
                }
        }
        .frame(width: width, height: halfHeight, alignment: alignment)
    }

    private func cardShape(alignment: Alignment) -> UnevenRoundedRectangle {
        let isTop = alignment == .top
        return UnevenRoundedRectangle(
            topLeadingRadius:     isTop ? radiusLarge : radiusSmall,
            bottomLeadingRadius:  isTop ? radiusSmall : radiusLarge,
            bottomTrailingRadius: isTop ? radiusSmall : radiusLarge,
            topTrailingRadius:    isTop ? radiusLarge : radiusSmall
        )
    }
}

#Preview {
    HStack(spacing: 4) {
        FlipTile(digit: 1, size: 200)
        FlipTile(digit: 2, size: 200)
        FlipTile(digit: 3, size: 200)
    }
    .padding()
    .background(Color.black)
}
