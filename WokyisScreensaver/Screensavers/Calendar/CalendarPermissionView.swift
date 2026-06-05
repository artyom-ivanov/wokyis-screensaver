import SwiftUI

struct CalendarPermissionView: View {
    let theme: CalendarTheme
    let authStatus: CalendarAuthStatus
    let onRequestAccess: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(theme.primaryText)

            Text("Calendar Access Required")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(theme.primaryText)

            Text("Wokyis needs access to your calendars\nto display your agenda.")
                .font(.system(size: 14))
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                if authStatus == .denied {
                    onOpenSettings()
                } else {
                    onRequestAccess()
                }
            } label: {
                Text(authStatus == .denied ? "Open System Settings" : "Grant Access")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.background)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(theme.primaryText, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}
