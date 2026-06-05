import SwiftUI
import EventKit

private let hourHeight: CGFloat = 80
private let timeColumnWidth: CGFloat = 60

struct TimelineView: View {
    let events: [EKEvent]
    let theme: CalendarTheme

    @State private var now = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var currentHour: Int {
        Calendar.current.component(.hour, from: now)
    }
    private var currentMinute: Int {
        Calendar.current.component(.minute, from: now)
    }
    private var currentTimeY: CGFloat {
        CGFloat(currentHour) * hourHeight + CGFloat(currentMinute) / 60.0 * hourHeight
    }

    private func startOfToday() -> Date {
        Calendar.current.startOfDay(for: now)
    }

    private func yOffset(for date: Date) -> CGFloat {
        let seconds = date.timeIntervalSince(startOfToday())
        return CGFloat(seconds / 3600) * hourHeight
    }

    private func height(for event: EKEvent) -> CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        return max(CGFloat(duration / 3600) * hourHeight, 36)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Hour grid
                    VStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            HStack(alignment: .top, spacing: 0) {
                                Text(hourLabel(hour))
                                    .font(.system(size: 11))
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
                    ForEach(events, id: \.eventIdentifier) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            if event.travelTime > 0 {
                                TravelTimeBlockView(travelTime: event.travelTime, theme: theme)
                            }
                            EventCardView(event: event, theme: theme)
                        }
                        .padding(.leading, timeColumnWidth + 8)
                        .padding(.trailing, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(y: yOffset(for: event.startDate))
                    }

                    // Current time indicator
                    HStack(spacing: 0) {
                        Text(currentTimeLabel())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(theme.timeIndicator)
                            .frame(width: timeColumnWidth, alignment: .trailing)
                            .padding(.trailing, 4)

                        Rectangle()
                            .fill(theme.timeIndicator)
                            .frame(height: 1.5)
                            .frame(maxWidth: .infinity)
                    }
                    .offset(y: currentTimeY)
                    .id("currentTime")
                }
                .frame(minHeight: CGFloat(24) * hourHeight)
                .padding(.bottom, 40)
            }
            .onAppear {
                let scrollHour = max(currentHour - 2, 0)
                proxy.scrollTo("hour_\(scrollHour)", anchor: .top)
            }
            .onReceive(timer) { now = $0 }
            .overlay(hourAnchorOverlay)
        }
    }

    // Invisible anchors for scrolling to specific hours
    private var hourAnchorOverlay: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<24, id: \.self) { hour in
                Color.clear
                    .frame(height: 1)
                    .offset(y: CGFloat(hour) * hourHeight)
                    .id("hour_\(hour)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
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
