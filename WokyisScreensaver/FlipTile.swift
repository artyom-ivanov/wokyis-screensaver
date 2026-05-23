import SwiftUI

/// One digit. When `digit` changes, plays a two-stage X-axis flip
/// (0 → −90°, easeIn 0.3 s; mirror content; −90° → −180°, easeOut 0.3 s).
struct FlipTile: View {
    let digit: Int
    let size: CGFloat

    /// Visible digit on the static bottom layer.
    /// Updated to `digit` *before* the flip starts — the new digit's bottom
    /// half is what the flying top layer reveals as it rotates past −90°.
    @State private var bottomLayerDigit: Int

    /// Visible digit on the flying top layer.
    /// Holds the OLD digit during the first half of the flip (0 → −90°);
    /// swapped to the new digit at the midpoint when the layer is edge-on.
    @State private var topLayerDigit: Int

    @State private var angleX: CGFloat = 0
    @State private var angleY: CGFloat = 0
    @State private var angleZ: CGFloat = 0
    @State private var shadeOpacity: CGFloat = 0

    @State private var flipTask: Task<Void, Never>?

    init(digit: Int, size: CGFloat) {
        self.digit = digit
        self.size = size
        self._bottomLayerDigit = State(initialValue: digit)
        self._topLayerDigit = State(initialValue: digit)
    }

    // MARK: layout constants
    private var width: CGFloat { size * 0.72 }
    private var height: CGFloat { size * 1.10 }
    private var gap: CGFloat { max(2, size * 0.012) }
    private var halfHeight: CGFloat { (height - gap) / 2 }
    private var radiusLarge: CGFloat { size * 0.08 }
    private var radiusSmall: CGFloat { size * 0.015 }

    private let tileColor = Color(white: 0.18)
    private let digitColor = Color(white: 0.92)
    /// One half of the full flip (0 → −90° or −90° → −180°). Full flip = 2 × this.
    private let stageDuration: TimeInterval = 0.3

    var body: some View {
        ZStack {
            // Static bottom layer: shows `bottomLayerDigit`.
            // While idle, its top half is hidden behind the un-rotated top layer.
            staticTile(showing: bottomLayerDigit)

            // Flying top layer. Holds `topLayerDigit`, rotates around its
            // bottom edge (top half flips down).
            flyingTopLayer(showing: topLayerDigit)
        }
        .frame(width: width, height: height)
        .onChange(of: digit) { _, newValue in
            startFlip(to: newValue)
        }
        .onDisappear { flipTask?.cancel() }
    }

    // MARK: subviews

    private func staticTile(showing value: Int) -> some View {
        VStack(spacing: gap) {
            halfCard(alignment: .top, value: value)
            halfCard(alignment: .bottom, value: value)
        }
    }

    /// The flying top layer renders BOTH halves of a tile but they appear
    /// during different stages of the flip: the upper half (which is the
    /// part anchored at `.top`) is what the user sees during the first half
    /// of the rotation. After the mid-flip Y/Z mirror, the lower half becomes
    /// what the user sees as the rotation completes.
    private func flyingTopLayer(showing value: Int) -> some View {
        VStack(spacing: gap) {
            halfCard(alignment: .top, value: value)
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [Color.black.opacity(shadeOpacity), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: halfHeight)
                    .allowsHitTesting(false)
                }
            halfCard(alignment: .bottom, value: value)
        }
        // Mid-flip mirror — applied to the *content* of the rotating layer,
        // not the X rotation itself.
        .rotation3DEffect(.degrees(angleY), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(angleZ), axis: (x: 0, y: 0, z: 1))
        // Main flip rotation, around the centre line of the tile.
        .rotation3DEffect(
            .degrees(angleX),
            axis: (x: 1, y: 0, z: 0),
            anchor: .center,
            anchorZ: 0,
            perspective: 0.5
        )
    }

    private func halfCard(alignment: Alignment, value: Int) -> some View {
        ZStack(alignment: alignment) {
            cardShape(alignment: alignment)
                .fill(tileColor)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                .frame(height: halfHeight)

            Text("\(value)")
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

    // MARK: animation

    private func startFlip(to newDigit: Int) {
        flipTask?.cancel()
        flipTask = Task { @MainActor in
            bottomLayerDigit = newDigit

            withAnimation(.easeIn(duration: stageDuration)) {
                angleX = -90
                shadeOpacity = 0.6
            }
            try? await Task.sleep(nanoseconds: UInt64(stageDuration * 1_000_000_000))
            if Task.isCancelled {
                angleX = 0; angleY = 0; angleZ = 0
                shadeOpacity = 0
                return
            }

            // At edge-on: clear the shade so the back side starts bright,
            // mirror the content, swap to the new digit.
            shadeOpacity = 0
            angleY = 180
            angleZ = 180
            topLayerDigit = newDigit

            withAnimation(.easeOut(duration: stageDuration)) {
                angleX = -180
            }
            try? await Task.sleep(nanoseconds: UInt64(stageDuration * 1_000_000_000))
            if Task.isCancelled {
                angleX = 0; angleY = 0; angleZ = 0
                shadeOpacity = 0
                return
            }

            angleX = 0
            angleY = 0
            angleZ = 0
        }
    }
}

#Preview {
    @Previewable @State var d: Int = 0
    VStack(spacing: 20) {
        FlipTile(digit: d, size: 200)
        Button("flip → \((d + 1) % 10)") { d = (d + 1) % 10 }
    }
    .padding()
    .background(Color.black)
}
