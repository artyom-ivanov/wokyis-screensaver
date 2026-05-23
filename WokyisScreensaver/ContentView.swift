import SwiftUI
import AppKit

/// Reference-typed holder so updating the timer doesn't churn `@State`
/// (which would re-render the whole view tree on every mouse-pixel
/// move via `.onContinuousHover`).
private final class HoverState {
    var hideWork: DispatchWorkItem?
    var keyMonitor: Any?
}

struct ContentView: View {
    @AppStorage("selectedScreensaver") private var selectionRaw:     String = ScreensaverID.noise.rawValue
    @AppStorage("paletteID")           private var paletteRaw:       String = Palette.default.id
    @AppStorage("flipClockTheme")      private var flipClockThemeRaw: String = FlipClockTheme.default.id
    @State private var noiseSettings = Settings()
    @State private var golReseedTick: Int = 0
    @State private var pickerVisible: Bool = false
    @State private var hoverState = HoverState()

    private var selection: Binding<ScreensaverID> {
        Binding(
            get: { ScreensaverID(rawValue: selectionRaw) ?? .noise },
            set: { selectionRaw = $0.rawValue }
        )
    }

    private var palette: Binding<Palette> {
        Binding(
            get: { Palette.by(id: paletteRaw) },
            set: { paletteRaw = $0.id }
        )
    }

    private var flipClockTheme: Binding<FlipClockTheme> {
        Binding(
            get: { FlipClockTheme.by(id: flipClockThemeRaw) },
            set: { flipClockThemeRaw = $0.id }
        )
    }

    /// Whether the screensaver currently shows a light background, so the
    /// hover-pickers can switch to dark-on-light styling for legibility.
    private var pickerOnLightBackground: Bool {
        switch selection.wrappedValue {
        case .flipClock: return flipClockTheme.wrappedValue.id == FlipClockTheme.light.id
        default:         return false
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            screensaverView(for: selection.wrappedValue)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    if selection.wrappedValue == .gameOfLife {
                        golReseedTick &+= 1
                    }
                }

            VStack {
                if pickerVisible {
                    ScreensaverPicker(
                        selection: selection,
                        onLightBackground: pickerOnLightBackground
                    )
                    .padding(.top, 20)
                    .transition(.opacity)
                }
                Spacer()
                if pickerVisible && selection.wrappedValue == .gameOfLife {
                    PalettePicker(selection: palette)
                        .padding(.bottom, 20)
                        .transition(.opacity)
                }
                if pickerVisible && selection.wrappedValue == .flipClock {
                    FlipClockThemePicker(
                        selection: flipClockTheme,
                        onLightBackground: pickerOnLightBackground
                    )
                    .padding(.bottom, 20)
                    .transition(.opacity)
                }
            }
            .allowsHitTesting(pickerVisible)
        }
        .animation(.easeInOut(duration: 0.18), value: pickerVisible)
        .onContinuousHover { phase in
            switch phase {
            case .active: bumpHover()
            case .ended:
                hoverState.hideWork?.cancel()
                if pickerVisible { pickerVisible = false }
            }
        }
        .onAppear { installKeyMonitor() }
    }

    @ViewBuilder
    private func screensaverView(for id: ScreensaverID) -> some View {
        switch id {
        case .noise:
            MetalView(settings: noiseSettings)
        case .gameOfLife:
            GameOfLifeView(palette: palette.wrappedValue, reseedTick: golReseedTick)
        case .flipClock:
            FlipClockView(theme: flipClockTheme.wrappedValue)
        }
    }

    private func bumpHover() {
        if !pickerVisible { pickerVisible = true }
        hoverState.hideWork?.cancel()
        let work = DispatchWorkItem { pickerVisible = false }
        hoverState.hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func installKeyMonitor() {
        guard hoverState.keyMonitor == nil else { return }
        hoverState.keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Esc
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }
}
