import SwiftUI
import EventKit

struct CalendarSetupView: View {
    let calendars: [EKCalendar]
    @Binding var selectedIDs: Set<String>
    let theme: CalendarTheme
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                Text("Choose Calendars")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                Divider()
                    .background(theme.secondaryText.opacity(0.2))

                CalendarPicker(
                    calendars: calendars,
                    selectedIDs: $selectedIDs,
                    onLightBackground: theme.id == CalendarTheme.light.id
                )
                .frame(width: 320)

                Divider()
                    .background(theme.secondaryText.opacity(0.2))

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.secondaryText.opacity(0.15), lineWidth: 1)
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
