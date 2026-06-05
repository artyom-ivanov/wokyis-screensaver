import SwiftUI

struct CalendarHeaderView: View {
    let theme: CalendarTheme
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMMM"
        return f
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(theme.secondaryText)
                Text(dateFormatter.string(from: now))
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
            }

            Spacer()

            Text(timeFormatter.string(from: now))
                .font(.system(size: 68, weight: .bold))
                .foregroundStyle(theme.primaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .onReceive(timer) { now = $0 }
    }
}
