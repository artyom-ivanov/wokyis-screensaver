import SwiftUI
import EventKit

private let hourHeight: CGFloat = 110
private let timeColumnWidth: CGFloat = 72
private let eventSpacing: CGFloat = 4

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

    @State private var now = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

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

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                GeometryReader { geo in
                    let eventsAreaWidth = geo.size.width - timeColumnWidth - 8 - 16
                    let positioned = assignColumns(events)

                    ZStack(alignment: .topLeading) {
                        // Hour grid
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                HStack(alignment: .top, spacing: 0) {
                                    Text(hourLabel(hour))
                                        .font(.system(size: 13))
                                        .foregroundStyle(theme.secondaryText)
                                        .frame(width: timeColumnWidth, alignment: .trailing)
                                        .padding(.trailing, 8)

                                    Rectangle()
                                        .fill(theme.secondaryText.opacity(0.15))
                                        .frame(height: 0.5)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(height: hourHeight, alignment: .top)
                            }
                        }

                        // Events
                        ForEach(Array(positioned.enumerated()), id: \.offset) { _, pe in
                            let colWidth = eventsAreaWidth / CGFloat(pe.totalColumns)
                            let xOffset = timeColumnWidth + 8 + colWidth * CGFloat(pe.column)
                            EventCardView(event: pe.event, theme: theme)
                                .frame(width: colWidth - eventSpacing, height: eventHeight(for: pe.event))
                                .offset(x: xOffset, y: yOffset(for: pe.event.startDate))
                        }

                        // Current time indicator
                        HStack(spacing: 0) {
                            Text(currentTimeLabel())
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(theme.timeIndicator)
                                .frame(width: timeColumnWidth, alignment: .trailing)
                                .padding(.trailing, 4)

                            Rectangle()
                                .fill(theme.timeIndicator)
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                        .offset(y: currentTimeY)
                        .id("currentTime")

                        // Invisible scroll anchors
                        ForEach(0..<24, id: \.self) { hour in
                            Color.clear
                                .frame(width: 1, height: 1)
                                .offset(y: CGFloat(hour) * hourHeight)
                                .id("hour_\(hour)")
                        }
                    }
                    .frame(width: geo.size.width, height: CGFloat(24) * hourHeight + 40)
                }
                .frame(height: CGFloat(24) * hourHeight + 40)
            }
            .onAppear {
                let scrollHour = max(currentHour - 2, 0)
                proxy.scrollTo("hour_\(scrollHour)", anchor: .top)
            }
            .onReceive(timer) { now = $0 }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let d = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        let f = DateFormatter()
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)
        return f.string(from: d)
    }

    private func currentTimeLabel() -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: now)
    }
}
