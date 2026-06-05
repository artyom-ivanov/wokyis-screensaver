import SwiftUI
import EventKit

struct TravelTimeBlockView: View {
    let travelTime: TimeInterval
    let theme: CalendarTheme

    private var label: String {
        let minutes = Int(travelTime / 60)
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let rem = minutes % 60
        return rem == 0 ? "\(hours) hr" : "\(hours) hr \(rem) min"
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "car.fill")
                .font(.system(size: 11))
            Text(label)
                .font(.system(size: 12))
        }
        .foregroundStyle(theme.secondaryText)
        .padding(.leading, 52)
    }
}
