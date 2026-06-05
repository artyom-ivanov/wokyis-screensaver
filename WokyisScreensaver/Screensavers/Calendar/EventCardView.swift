import SwiftUI
import EventKit

struct EventCardView: View {
    let event: EKEvent
    let theme: CalendarTheme

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }

    private var isMaybe: Bool {
        event.attendees?.first(where: { $0.isCurrentUser })?.participantStatus == .tentative
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(event.title ?? "")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(theme.primaryText)
                .lineLimit(2)

            HStack(spacing: 10) {
                Text("\(timeFormatter.string(from: event.startDate)) – \(timeFormatter.string(from: event.endDate))")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.secondaryText)

                if let loc = event.location, !loc.isEmpty {
                    Text(loc)
                        .font(.system(size: 15))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(1)
                }

                if isMaybe {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 13))
                        Text("Maybe")
                            .font(.system(size: 15))
                    }
                    .foregroundStyle(theme.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 10))
    }
}
