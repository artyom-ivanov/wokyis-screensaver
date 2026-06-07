import SwiftUI
import EventKit

struct CalendarPicker: View {
    let calendars: [EKCalendar]
    @Binding var selectedIDs: Set<String>
    var onLightBackground: Bool = false

    private var foreground: Color { onLightBackground ? .black : .white }
    private var secondaryForeground: Color { onLightBackground ? Color.black.opacity(0.5) : Color.white.opacity(0.5) }
    private func isSelected(_ cal: EKCalendar) -> Bool { selectedIDs.contains(cal.calendarIdentifier) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(calendars, id: \.calendarIdentifier) { cal in
                Button {
                    if isSelected(cal) {
                        selectedIDs.remove(cal.calendarIdentifier)
                    } else {
                        selectedIDs.insert(cal.calendarIdentifier)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(cgColor: cal.cgColor))
                            .frame(width: 11, height: 11)

                        Text(cal.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(foreground)

                        Spacer()

                        if isSelected(cal) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(foreground)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                if cal.calendarIdentifier != calendars.last?.calendarIdentifier {
                    Divider()
                        .background(onLightBackground ? Color.black.opacity(0.08) : Color.white.opacity(0.08))
                        .padding(.horizontal, 18)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
