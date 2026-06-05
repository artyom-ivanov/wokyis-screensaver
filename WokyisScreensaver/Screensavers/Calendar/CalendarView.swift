import SwiftUI

struct CalendarView: View {
    @ObservedObject var store: CalendarStore
    let theme: CalendarTheme

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            switch store.authStatus {
            case .notDetermined, .denied:
                CalendarPermissionView(
                    theme: theme,
                    authStatus: store.authStatus,
                    onRequestAccess: { Task { await store.requestAccess() } },
                    onOpenSettings: { store.openSystemSettings() }
                )
            case .authorized:
                VStack(spacing: 0) {
                    CalendarHeaderView(theme: theme)

                    Divider()
                        .background(theme.secondaryText.opacity(0.3))

                    if store.events.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(theme.secondaryText)
                            Text("No events today")
                                .font(.system(size: 16))
                                .foregroundStyle(theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        AgendaTimelineView(events: store.events, theme: theme)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                }
            }
        }
    }
}
