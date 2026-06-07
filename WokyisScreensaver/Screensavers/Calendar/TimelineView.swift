import SwiftUI
import EventKit

private let hourHeight: CGFloat = 220
private let timeColumnWidth: CGFloat = 100
private let eventSpacing: CGFloat = 10

private struct PositionedEvent {
    let event: EKEvent
    let column: Int
    let totalColumns: Int
}

private func assignColumns(_ events: [EKEvent]) -> [PositionedEvent] {
    let sorted = events.sorted { $0.startDate < $1.startDate }
    var columnEnds: [Date] = []
    var assignments: [Int] = []

    for event in sorted {
        var placed = false
        for i in 0..<columnEnds.count {
            if event.startDate >= columnEnds[i] {
                columnEnds[i] = event.endDate
                assignments.append(i)
                placed = true
                break
            }
        }
        if !placed {
            assignments.append(columnEnds.count)
            columnEnds.append(event.endDate)
        }
    }

    return sorted.enumerated().map { idx, event in
        let col = assignments[idx]
        var maxCol = col
        for (jdx, other) in sorted.enumerated() {
            guard jdx != idx else { continue }
            if other.startDate < event.endDate && other.endDate > event.startDate {
                maxCol = max(maxCol, assignments[jdx])
            }
        }
        return PositionedEvent(event: event, column: col, totalColumns: maxCol + 1)
    }
}

struct AgendaTimelineView: View {
    let events: [EKEvent]
    let theme: CalendarTheme
    var scrollTrigger: UUID = UUID()
    var showAccent: Bool = true

    @State private var now = Date()
    @State private var lastManualScroll: Date = .distantPast

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let autoScrollTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var currentHour: Int { Calendar.current.component(.hour, from: now) }
    private var currentMinute: Int { Calendar.current.component(.minute, from: now) }
    private var currentTimeY: CGFloat {
        CGFloat(currentHour) * hourHeight + CGFloat(currentMinute) / 60.0 * hourHeight
    }

    private func startOfToday() -> Date { Calendar.current.startOfDay(for: now) }

    private func yOffset(for date: Date) -> CGFloat {
        CGFloat(date.timeIntervalSince(startOfToday()) / 3600) * hourHeight
    }

    private func eventHeight(for event: EKEvent) -> CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        return max(CGFloat(duration / 3600) * hourHeight - eventSpacing, 44)
    }

    private var scrollTargetY: CGFloat {
        max(currentTimeY - (20.0 / 60.0) * hourHeight, 0)
    }

    private func scrollToCurrent(proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.8)) {
            proxy.scrollTo("scrollTarget", anchor: .top)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                GeometryReader { geo in
                    let eventsAreaWidth = geo.size.width - timeColumnWidth - 8 - 16
                    let positioned = assignColumns(events)

                    ZStack(alignment: .topLeading) {
                        // Hour grid — rows carry the scroll anchor IDs
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                HStack(alignment: .top, spacing: 0) {
                                    Text(hourLabel(hour))
                                        .font(.system(size: 32))
                                        .lineLimit(1)
                                        .foregroundStyle(theme.secondaryText)
                                        .frame(width: timeColumnWidth, alignment: .trailing)
                                        .padding(.trailing, 20)
                                        .offset(y: -18)

                                    Rectangle()
                                        .fill(theme.secondaryText.opacity(0.15))
                                        .frame(height: 0.5)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(height: hourHeight, alignment: .top)
                                .id("hour_\(hour)")
                            }
                        }

                        // Events
                        ForEach(Array(positioned.enumerated()), id: \.offset) { _, pe in
                            let colWidth = eventsAreaWidth / CGFloat(pe.totalColumns)
                            let xOffset = (timeColumnWidth + 20) + 8 + colWidth * CGFloat(pe.column)
                            let isPast = pe.event.endDate < now
                            EventCardView(event: pe.event, theme: theme, isOverlapping: pe.totalColumns > 1, showAccent: showAccent)
                                .frame(width: colWidth - eventSpacing, height: eventHeight(for: pe.event))
                                .offset(x: xOffset, y: yOffset(for: pe.event.startDate))
                                .opacity(isPast ? 0.35 : 1.0)
                        }

                        // Scroll target anchor: current time minus 20 min
                        // VStack spacer gives real layout height so proxy.scrollTo works
                        VStack(spacing: 0) {
                            Color.clear.frame(height: max(scrollTargetY, 0))
                            Color.clear.frame(width: 1, height: 1).id("scrollTarget")
                        }

                        // Current time indicator
                        HStack(spacing: 0) {
                            Circle()
                                .fill(theme.timeIndicator)
                                .frame(width: 20, height: 20)
                                .padding(.leading, 8)

                            Rectangle()
                                .fill(theme.timeIndicator)
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                        .offset(y: currentTimeY)
                    }
                    .frame(width: geo.size.width, height: CGFloat(24) * hourHeight + 40)
                }
                .frame(height: CGFloat(24) * hourHeight + 40)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in lastManualScroll = Date() }
            )
            .onAppear { scrollToCurrent(proxy: proxy) }
            .onChange(of: scrollTrigger) { scrollToCurrent(proxy: proxy) }
            .onReceive(timer) { now = $0 }
            .onReceive(autoScrollTimer) { _ in
                if Date().timeIntervalSince(lastManualScroll) >= 30 {
                    scrollToCurrent(proxy: proxy)
                }
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let d = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        let f = DateFormatter()
        let uses24h = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)?.contains("H") == true
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: uses24h ? "Hmm" : "j", options: 0, locale: Locale.current)
        return f.string(from: d)
    }

    private func currentTimeLabel() -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: now)
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
