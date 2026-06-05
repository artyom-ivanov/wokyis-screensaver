import SwiftUI
import EventKit

struct CalendarPicker: View {
    let calendars: [EKCalendar]
    @Binding var selectedIDs: Set<String>
    var onLightBackground: Bool = false

    private var foreground: Color { onLightBackground ? .black : .white }
    private func isSelected(_ cal: EKCalendar) -> Bool { selectedIDs.contains(cal.calendarIdentifier) }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(calendars, id: \.calendarIdentifier) { cal in
                Button {
                    if isSelected(cal) {
                        selectedIDs.remove(cal.calendarIdentifier)
                    } else {
                        selectedIDs.insert(cal.calendarIdentifier)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(cgColor: cal.cgColor))
                            .frame(width: 8, height: 8)
                        Text(cal.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(foreground)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            isSelected(cal)
                                ? (onLightBackground ? Color.black.opacity(0.18) : Color.white.opacity(0.22))
                                : (onLightBackground ? Color.black.opacity(0.06) : Color.white.opacity(0.08))
                        )
                    )
                    .overlay(
                        Capsule().stroke(
                            isSelected(cal) ? foreground : Color.clear,
                            lineWidth: 1.5
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
