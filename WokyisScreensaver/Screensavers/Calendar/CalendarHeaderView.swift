import SwiftUI
import EventKit

struct CalendarHeaderView: View {
    let theme: CalendarTheme
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(theme.secondaryText)
                Text(dateFormatter.string(from: now))
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                    .minimumScaleFactor(0.5)
            }

            Spacer()

            Text(timeFormatter.string(from: now))
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(theme.primaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .onReceive(timer) { now = $0 }
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
