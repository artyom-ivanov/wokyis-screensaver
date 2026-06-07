import SwiftUI
import EventKit

struct CalendarView: View {
    @ObservedObject var store: CalendarStore
    let theme: CalendarTheme
    var scrollTrigger: UUID = UUID()
    var showAccent: Bool = true
    @Binding var showingSetup: Bool
    @Binding var selectedCalendarIDs: Set<String>

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
                if showingSetup {
                    CalendarSetupView(
                        calendars: store.availableCalendars,
                        selectedIDs: $selectedCalendarIDs,
                        theme: theme,
                        onDone: { showingSetup = false }
                    )
                } else {
                    VStack(spacing: 0) {
                        let allDay = store.events.filter(\.isAllDay)
                        let timed  = store.events.filter { !$0.isAllDay }

                        CalendarHeaderView(theme: theme, allDayEvents: allDay)

                        Divider()
                            .background(theme.secondaryText.opacity(0.3))

                        if timed.isEmpty && allDay.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 36, weight: .light))
                                    .foregroundStyle(theme.secondaryText)
                                Text("No events today")
                                    .font(.system(size: 16))
                                    .foregroundStyle(theme.secondaryText)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if !timed.isEmpty {
                            AgendaTimelineView(events: timed, theme: theme, scrollTrigger: scrollTrigger, showAccent: showAccent)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
private func mockEvent(
    _ store: EKEventStore,
    title: String,
    startHour: Double,
    durationMinutes: Int,
    location: String? = nil
) -> EKEvent {
    let e = EKEvent(eventStore: store)
    e.title = title
    let today = Calendar.current.startOfDay(for: Date())
    e.startDate = today.addingTimeInterval(startHour * 3600)
    e.endDate = e.startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
    e.location = location
    return e
}

#Preview("Dark", traits: .fixedLayout(width: 1280, height: 720)) {
    let ekStore = EKEventStore()
    let events: [EKEvent] = [
        mockEvent(ekStore, title: "Morning standup",  startHour: 9.0,  durationMinutes: 30,  location: "Zoom"),
        mockEvent(ekStore, title: "1:1 with Priya",   startHour: 10.5, durationMinutes: 60,  location: "Room Aster"),
        mockEvent(ekStore, title: "Design review",    startHour: 14.0, durationMinutes: 60,  location: "Room Vega"),
        mockEvent(ekStore, title: "Lunch with Alex",  startHour: 13.0, durationMinutes: 90,  location: "Café Norte"),
        mockEvent(ekStore, title: "Team sync",        startHour: 16.0, durationMinutes: 45),
        mockEvent(ekStore, title: "Deep work",        startHour: 10.5, durationMinutes: 120, location: "Home"),
    ]

    ZStack {
        CalendarTheme.dark.background.ignoresSafeArea()
        VStack(spacing: 0) {
            CalendarHeaderView(theme: .dark)
            Divider().background(CalendarTheme.dark.secondaryText.opacity(0.3))
            AgendaTimelineView(events: events, theme: .dark)
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
    }
}

#Preview("Light", traits: .fixedLayout(width: 1280, height: 720)) {
    let ekStore = EKEventStore()
    let events: [EKEvent] = [
        mockEvent(ekStore, title: "Morning standup",  startHour: 9.0,  durationMinutes: 30,  location: "Zoom"),
        mockEvent(ekStore, title: "1:1 with Priya",   startHour: 10.5, durationMinutes: 60,  location: "Room Aster"),
        mockEvent(ekStore, title: "Design review",    startHour: 14.0, durationMinutes: 60,  location: "Room Vega"),
        mockEvent(ekStore, title: "Lunch with Alex",  startHour: 13.0, durationMinutes: 90,  location: "Café Norte"),
        mockEvent(ekStore, title: "Team sync",        startHour: 16.0, durationMinutes: 45),
        mockEvent(ekStore, title: "Deep work",        startHour: 10.5, durationMinutes: 120, location: "Home"),
    ]

    ZStack {
        CalendarTheme.light.background.ignoresSafeArea()
        VStack(spacing: 0) {
            CalendarHeaderView(theme: .light)
            Divider().background(CalendarTheme.light.secondaryText.opacity(0.3))
            AgendaTimelineView(events: events, theme: .light)
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
    }
}
#endif
