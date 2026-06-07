import SwiftUI
import EventKit

struct AllDayEventsView: View {
    let events: [EKEvent]
    let theme: CalendarTheme

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                Text(event.title ?? "")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 14)
    }
}
