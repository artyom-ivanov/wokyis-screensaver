import SwiftUI
import AppKit

struct ContentView: View {
    @State private var settings = Settings()

    var body: some View {
        MetalView(settings: settings)
            .ignoresSafeArea()
            .onAppear { installKeyMonitor() }
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
