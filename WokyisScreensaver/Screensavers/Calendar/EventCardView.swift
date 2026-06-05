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

    private var rsvpStatus: String? {
        guard let me = event.attendees?.first(where: { $0.isCurrentUser }) else { return nil }
        switch me.participantStatus {
        case .accepted: return "Going"
        case .tentative: return "Maybe"
        case .pending:   return "No reply"
        default: return nil
        }
    }

    private var rsvpIcon: String? {
        guard let me = event.attendees?.first(where: { $0.isCurrentUser }) else { return nil }
        switch me.participantStatus {
        case .accepted:  return "checkmark.circle.fill"
        case .tentative: return "questionmark.circle"
        case .pending:   return "circle"
        default: return nil
        }
    }

    private var isDashed: Bool {
        guard let me = event.attendees?.first(where: { $0.isCurrentUser }) else { return false }
        return me.participantStatus == .tentative || me.participantStatus == .pending
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title ?? "")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.primaryText)

            HStack(spacing: 8) {
                Text("\(timeFormatter.string(from: event.startDate)) – \(timeFormatter.string(from: event.endDate))")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondaryText)

                if let loc = event.location, !loc.isEmpty {
                    Text(loc)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.secondaryText)
                }

                if let icon = rsvpIcon, let status = rsvpStatus {
                    HStack(spacing: 3) {
                        Image(systemName: icon)
                            .font(.system(size: 10))
                        Text(status)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(theme.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isDashed ? theme.dashedBorder : theme.cardBorder,
                    style: isDashed
                        ? StrokeStyle(lineWidth: 1, dash: [4, 3])
                        : StrokeStyle(lineWidth: 1)
                )
        )
    }
}
