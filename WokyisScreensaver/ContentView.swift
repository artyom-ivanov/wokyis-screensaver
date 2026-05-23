import SwiftUI
import AppKit

struct ContentView: View {
    @AppStorage("selectedScreensaver") private var selectionRaw: String = ScreensaverID.noise.rawValue
    @AppStorage("paletteID")           private var paletteRaw:   String = Palette.default.id
    @State private var noiseSettings = Settings()
    @State private var golReseedTick: Int = 0
    @State private var pickerVisible: Bool = false
    @State private var hideWork: DispatchWorkItem?

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
                    ScreensaverPicker(selection: selection)
                        .padding(.top, 20)
                        .transition(.opacity)
                }
                Spacer()
                if pickerVisible && selection.wrappedValue == .gameOfLife {
                    PalettePicker(selection: palette)
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
                hideWork?.cancel()
                pickerVisible = false
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
        }
    }

    private func bumpHover() {
        pickerVisible = true
        hideWork?.cancel()
        let work = DispatchWorkItem { pickerVisible = false }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func installKeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Esc
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }
}
