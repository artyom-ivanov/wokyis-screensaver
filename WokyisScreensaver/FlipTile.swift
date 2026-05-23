import SwiftUI

/// One digit. When `digit` changes, plays a two-stage X-axis flip
/// (0 → −90°, easeIn 0.3 s; mirror content; −90° → −180°, easeOut 0.3 s).
///
/// Three layers compose the tile (z-order, back to front):
///   - `bottomStaticDigit` — bottom half. Holds the OLD digit throughout the
///     flip and snaps to NEW at the very end when the flying card "lands".
///   - `topStaticDigit` — top half. Set to NEW before the flip starts; it
///     sits behind the un-rotated flying card and becomes visible as the
///     flying card rotates away during stage 1.
///   - `flyingDigit` — top half, on top, rotates around the split-line axis.
///     Shows OLD during stage 1; swapped to NEW at the midpoint when the
///     card is edge-on (invisible) so stage 2 lands NEW on top of the old
///     bottom-half, which then snaps to NEW under cover of the flying card.
struct FlipTile: View {
    let digit: Int
    let size: CGFloat

    @State private var bottomStaticDigit: Int
    @State private var topStaticDigit: Int
    @State private var flyingDigit: Int

    @State private var angleX: CGFloat = 0
    @State private var angleY: CGFloat = 0
    @State private var angleZ: CGFloat = 0
    @State private var shadeOpacity: CGFloat = 0

    @State private var flipTask: Task<Void, Never>?

    init(digit: Int, size: CGFloat) {
        self.digit = digit
        self.size = size
        self._bottomStaticDigit = State(initialValue: digit)
        self._topStaticDigit = State(initialValue: digit)
        self._flyingDigit = State(initialValue: digit)
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
    private let stageDuration: TimeInterval = 0.3

    var body: some View {
        ZStack {
            // Static bottom section: holds OLD until the flying card lands.
            halfCard(alignment: .bottom, value: bottomStaticDigit)

            // Top section. The flying (rotating) half-card sits in front of a
            // static top-aligned background that's pre-set to NEW and emerges
            // as the flying card rotates away. Bundling them together with
            // `.background` (so they're a single composited unit) and putting
            // zIndex(1) on the whole section is what reliably keeps this
            // assembly above the static bottom half throughout the rotation;
            // siblings-with-zIndex doesn't survive SwiftUI's depth-aware
            // compositing once perspective is in play.
            flyingTopHalf(showing: flyingDigit)
                .background {
                    halfCard(alignment: .top, value: topStaticDigit)
                }
                .zIndex(1)
        }
        .frame(width: width, height: height)
        .onChange(of: digit) { _, newValue in
            startFlip(to: newValue)
        }
        .onDisappear { flipTask?.cancel() }
    }

    /// Half-card view. The outer frame is FULL tile height; the content
    /// (rounded shape + masked digit) lives in only one half, picked by
    /// `alignment`. The full-height frame is load-bearing: it makes the
    /// geometric centre of this view coincide with the split line, which is
    /// the pivot the flying card rotates around.
    private func halfCard(alignment: Alignment, value: Int) -> some View {
        ZStack(alignment: alignment) {
            cardShape(alignment: alignment)
                .fill(tileColor)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                .frame(width: width, height: halfHeight)

            Text("\(value)")
                .font(.system(size: size, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundStyle(digitColor)
                .frame(width: width, height: height)
                .mask(alignment: alignment) {
                    Rectangle().frame(height: halfHeight)
                }
        }
        .frame(width: width, height: height, alignment: alignment)
    }

    private func flyingTopHalf(showing value: Int) -> some View {
        halfCard(alignment: .top, value: value)
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.black.opacity(shadeOpacity), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: width, height: halfHeight)
                .allowsHitTesting(false)
            }
            // Mid-flip content mirror. At angleX = −90 the card is edge-on
            // (invisible); we then snap angleY and angleZ to 180 so the back
            // face reads correctly once it rotates into view in stage 2.
            .rotation3DEffect(.degrees(angleY), axis: (x: 0, y: 1, z: 0))
            .rotation3DEffect(.degrees(angleZ), axis: (x: 0, y: 0, z: 1))
            // Main flip rotation. `anchor: .center` of a full-height frame
            // puts the pivot exactly at the split line.
            .rotation3DEffect(
                .degrees(angleX),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.5
            )
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
            // The top-half behind the flying card is pre-set to NEW: it will
            // emerge as the flying card rotates away during stage 1.
            topStaticDigit = newDigit

            withAnimation(.easeIn(duration: stageDuration)) {
                angleX = -90
                shadeOpacity = 0.6
            }
            try? await Task.sleep(nanoseconds: UInt64(stageDuration * 1_000_000_000))
            if Task.isCancelled {
                resetTo(newDigit)
                return
            }

            // Edge-on instant: clear shade, apply content mirror, swap the
            // flying digit so stage 2's back-side rotation shows NEW.
            shadeOpacity = 0
            angleY = 180
            angleZ = 180
            flyingDigit = newDigit

            withAnimation(.easeOut(duration: stageDuration)) {
                angleX = -180
            }
            try? await Task.sleep(nanoseconds: UInt64(stageDuration * 1_000_000_000))
            if Task.isCancelled {
                resetTo(newDigit)
                return
            }

            // Landing. At angleX = −180 the flying card is occluding the OLD
            // bottom-half. Snap angles back to 0 and bottomStatic to NEW in
            // the same render pass — visually seamless because the flying
            // card is now back at the top showing NEW.
            angleX = 0
            angleY = 0
            angleZ = 0
            bottomStaticDigit = newDigit
        }
    }

    private func resetTo(_ newDigit: Int) {
        angleX = 0
        angleY = 0
        angleZ = 0
        shadeOpacity = 0
        topStaticDigit = newDigit
        flyingDigit = newDigit
        bottomStaticDigit = newDigit
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
