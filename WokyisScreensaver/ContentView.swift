import SwiftUI
import AppKit

struct ContentView: View {
    @State private var settings = Settings()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MetalView(settings: settings)
                .ignoresSafeArea()
            if settings.showPanel {
                SettingsPanel(settings: settings)
                    .padding(20)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: settings.showPanel)
        .onAppear { installKeyMonitor() }
    }

    private func installKeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 53: // Esc
                NSApp.terminate(nil)
                return nil
            case 4: // H
                settings.showPanel.toggle()
                return nil
            case 3: // F
                NSApp.windows.first?.toggleFullScreen(nil)
                return nil
            default:
                return event
            }
        }
    }
}
