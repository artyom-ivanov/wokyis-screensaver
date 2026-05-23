import SwiftUI
import AppKit

@main
struct WokyisScreensaverApp: App {
    init() {
        installEscapeMonitor()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    DispatchQueue.main.async {
                        NSApp.windows.first?.toggleFullScreen(nil)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }

    private func installEscapeMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }
}
