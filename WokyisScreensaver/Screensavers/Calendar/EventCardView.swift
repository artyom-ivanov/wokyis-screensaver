import SwiftUI
import EventKit

struct EventCardView: View {
    let event: EKEvent
    let theme: CalendarTheme
    var isOverlapping: Bool = false
    @AppStorage("calendarFontScale") private var fontScale: Double = 1.0

    private var isMaybe: Bool {
        event.attendees?.first(where: { $0.isCurrentUser })?.participantStatus == .tentative
    }

    private var durationLabel: String {
        let minutes = Int(event.endDate.timeIntervalSince(event.startDate) / 60)
        guard minutes > 0 else { return "" }
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)min"
    }

    private var titleView: some View {
        Text(event.title ?? "")
            .font(.system(size: 64 * fontScale, weight: .semibold))
            .foregroundStyle(theme.primaryText)
            .lineLimit(2)
            .minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metaView: some View {
        HStack(spacing: 8) {
            Text(durationLabel)
                .font(.system(size: 32 * fontScale))
                .foregroundStyle(theme.secondaryText)
            if isMaybe {
                HStack(spacing: 4) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 24 * fontScale))
                    Text("Maybe")
                        .font(.system(size: 28 * fontScale))
                }
                .foregroundStyle(theme.secondaryText)
            }
        }
    }

    var body: some View {
        Group {
            if isOverlapping {
                VStack(alignment: .leading, spacing: 4) {
                    titleView
                    metaView
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    titleView
                    metaView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 10))
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

