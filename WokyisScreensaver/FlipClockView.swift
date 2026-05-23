import SwiftUI

struct FlipClockView: View {
    static let showSeconds: Bool = true   // flip to false once visuals are validated
    let theme: FlipClockTheme

    @State private var digits: TimeDigits = .zero
    @State private var timer: Timer?
    @State private var is24Hour: Bool = FlipClockView.locale24Hour()
    @State private var isPM: Bool = false

    init(theme: FlipClockTheme = .dark) {
        self.theme = theme
    }

    var body: some View {
        GeometryReader { proxy in
            let size = tileSize(for: proxy.size, showSeconds: Self.showSeconds)
            ZStack {
                theme.background
                HStack(spacing: size * 0.08) {
                    pair(tens: digits.h1, units: digits.h2, size: size)
                    colonSeparator(size: size)
                    pair(tens: digits.m1, units: digits.m2, size: size)
                    if Self.showSeconds {
                        colonSeparator(size: size)
                        pair(tens: digits.s1, units: digits.s2, size: size)
                    }
                    if !is24Hour {
                        Text(isPM ? "PM" : "AM")
                            .font(.system(size: size * 0.18, weight: .semibold))
                            .fontDesign(.rounded)
                            .foregroundStyle(theme.ampm)
                            .padding(.leading, size * 0.10)
                    }
                }
                .padding(.horizontal, size * 0.72)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            digits = currentDigits()
            startTimer()
        }
        .onDisappear { stopTimer() }
    }

    // MARK: layout

    /// Picks a tile size such that the entire row (tiles + colons + HStack
    /// gaps + pair gaps + AM/PM widget + horizontal padding) fits in the
    /// container. Each term is the width of that element in `size` units.
    private func tileSize(for container: CGSize, showSeconds: Bool) -> CGFloat {
        let tileCount:  CGFloat = showSeconds ? 6 : 4
        let colonCount: CGFloat = showSeconds ? 2 : 1
        let outerGapCount: CGFloat = showSeconds ? 4 : 2   // gaps in outer HStack
        let pairGapCount:  CGFloat = showSeconds ? 3 : 2   // gaps inside each pair
        // AM/PM widget: HStack gap (0.08) + leading padding (0.10) + text (~0.28).
        let ampm: CGFloat = is24Hour ? 0 : 0.46
        let sidePadding: CGFloat = 2 * 0.72   // one digit-width per edge

        let widthDivisor = tileCount * 0.72
                         + colonCount * 0.25
                         + outerGapCount * 0.08
                         + pairGapCount * 0.04
                         + ampm
                         + sidePadding

        let widthDriven = container.width / widthDivisor
        let heightDriven = container.height * 0.65 / 1.10
        return min(widthDriven, heightDriven)
    }

    private func pair(tens: Int, units: Int, size: CGFloat) -> some View {
        HStack(spacing: size * 0.04) {
            FlipTile(digit: tens, size: size, theme: theme)
            FlipTile(digit: units, size: size, theme: theme)
        }
    }

    private func colonSeparator(size: CGFloat) -> some View {
        VStack(spacing: size * 0.30) {
            Circle().frame(width: size * 0.10, height: size * 0.10)
            Circle().frame(width: size * 0.10, height: size * 0.10)
        }
        .foregroundStyle(theme.colon)
        .frame(width: size * 0.25, height: size * 1.10)
    }

    // MARK: time source

    /// Flip animation will take ~0.6 s; offset the displayed time so the flip
    /// is centred on the wall-clock second rather than lagging behind it.
    private static let flipDuration: TimeInterval = 0.6

    private func startTimer() {
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                digits = currentDigits()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func currentDigits() -> TimeDigits {
        let now = Date().addingTimeInterval(Self.flipDuration)
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: now)
        let hour24 = comps.hour ?? 0
        let minute = comps.minute ?? 0
        let second = comps.second ?? 0

        let displayHour: Int
        if is24Hour {
            displayHour = hour24
        } else {
            let h = hour24 % 12
            displayHour = h == 0 ? 12 : h
        }
        isPM = hour24 >= 12

        return TimeDigits(
            h1: displayHour / 10,
            h2: displayHour % 10,
            m1: minute / 10,
            m2: minute % 10,
            s1: second / 10,
            s2: second % 10
        )
    }

    /// Probes the system locale for whether it uses 24-hour time.
    /// `dateFormat(fromTemplate: "j", ...)` returns "H" (24h) or "h" (12h).
    private static func locale24Hour() -> Bool {
        let template = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "H"
        return template.contains("H")
    }
}

struct TimeDigits: Equatable {
    var h1, h2, m1, m2, s1, s2: Int
    static let zero = TimeDigits(h1: 0, h2: 0, m1: 0, m2: 0, s1: 0, s2: 0)
}

#Preview {
    FlipClockView()
        .frame(width: 1200, height: 600)
}
