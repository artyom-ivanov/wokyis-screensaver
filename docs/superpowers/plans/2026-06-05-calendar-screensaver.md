# Calendar Screensaver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Calendar screensaver mode that shows today's agenda with a live clock, dark/light themes, multi-calendar picker, and inline EventKit permission handling.

**Architecture:** `CalendarStore` (ObservableObject) owns all EventKit interaction and publishes events/auth state. `CalendarView` renders three states: permission prompt, empty, and timeline. The screensaver is wired into `ContentView` following the same pattern as `FlipClock` (AppStorage for theme + selected calendars, hover pickers in the bottom panel).

**Tech Stack:** SwiftUI, EventKit (macOS 13+), AppStorage, Timer, NSWorkspace

---

## File Map

**Create:**
- `WokyisScreensaver/Screensavers/Calendar/CalendarTheme.swift` — dark/light color tokens (mirrors `FlipClockTheme`)
- `WokyisScreensaver/Screensavers/Calendar/CalendarStore.swift` — EventKit wrapper, ObservableObject
- `WokyisScreensaver/Screensavers/Calendar/CalendarPermissionView.swift` — permission prompt shown when access not granted
- `WokyisScreensaver/Screensavers/Calendar/CalendarHeaderView.swift` — top bar with date (left) and live clock (right)
- `WokyisScreensaver/Screensavers/Calendar/TravelTimeBlockView.swift` — travel time label rendered above an event card
- `WokyisScreensaver/Screensavers/Calendar/EventCardView.swift` — single event card (title, time, location, RSVP, travel time)
- `WokyisScreensaver/Screensavers/Calendar/TimelineView.swift` — scrollable time grid with events and current-time indicator
- `WokyisScreensaver/Screensavers/Calendar/CalendarView.swift` — top-level view, switches between permission/empty/timeline states
- `WokyisScreensaver/Screensavers/Calendar/CalendarThemePicker.swift` — dark/light toggle pill (mirrors `FlipClockThemePicker`)
- `WokyisScreensaver/Screensavers/Calendar/CalendarPicker.swift` — multi-select calendar list in hover panel

**Modify:**
- `WokyisScreensaver/App/ScreensaverID.swift` — add `.calendar` case
- `WokyisScreensaver/App/ContentView.swift` — add CalendarStore, wire screensaverView branch, add hover controls
- `WokyisScreensaver/Info.plist` — add `NSCalendarsFullAccessUsageDescription`
- `WokyisScreensaver.xcodeproj/project.pbxproj` — add all new Swift files to the build target

---

## Task 1: Info.plist + ScreensaverID

**Files:**
- Modify: `WokyisScreensaver/Info.plist`
- Modify: `WokyisScreensaver/App/ScreensaverID.swift`

- [ ] **Step 1: Add calendar usage description to Info.plist**

Open `WokyisScreensaver/Info.plist`. Add inside the `<dict>`:

```xml
<key>NSCalendarsFullAccessUsageDescription</key>
<string>Wokyis uses your calendar to display today's agenda on screen.</string>
```

- [ ] **Step 2: Add `.calendar` case to ScreensaverID**

Replace the entire content of `WokyisScreensaver/App/ScreensaverID.swift`:

```swift
import Foundation

enum ScreensaverID: String, CaseIterable, Identifiable {
    case noise    = "noise"
    case gameOfLife = "game_of_life"
    case flipClock  = "flip_clock"
    case calendar   = "calendar"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .noise:      return "Topographic"
        case .gameOfLife: return "Game of Life"
        case .flipClock:  return "Flip Clock"
        case .calendar:   return "Calendar"
        }
    }
}
```

- [ ] **Step 3: Build to confirm no errors**

In Xcode: Product → Build (⌘B). Expected: build succeeds (ScreensaverPicker will now show a "Calendar" pill automatically via `CaseIterable`).

- [ ] **Step 4: Commit**

```bash
git add WokyisScreensaver/Info.plist WokyisScreensaver/App/ScreensaverID.swift
git commit -m "feat: add calendar screensaver ID and calendar usage description"
```

---

## Task 2: CalendarTheme

**Files:**
- Create: `WokyisScreensaver/Screensavers/Calendar/CalendarTheme.swift`

- [ ] **Step 1: Create CalendarTheme.swift**

```swift
import SwiftUI

struct CalendarTheme: Identifiable, Equatable {
    let id: String
    let background: Color
    let cardFill: Color
    let primaryText: Color
    let secondaryText: Color
    let timeIndicator: Color
    let cardBorder: Color
    let dashedBorder: Color

    static let dark = CalendarTheme(
        id: "dark",
        background: Color(red: 0.04, green: 0.04, blue: 0.04),
        cardFill: Color(red: 0.11, green: 0.11, blue: 0.11),
        primaryText: .white,
        secondaryText: Color(white: 0.55),
        timeIndicator: .white,
        cardBorder: Color(white: 0.35),
        dashedBorder: Color(white: 0.25)
    )

    static let light = CalendarTheme(
        id: "light",
        background: Color(white: 0.96),
        cardFill: .white,
        primaryText: .black,
        secondaryText: Color(white: 0.43),
        timeIndicator: .black,
        cardBorder: Color(white: 0.70),
        dashedBorder: Color(white: 0.75)
    )

    static let all: [CalendarTheme] = [.dark, .light]
    static let `default`: CalendarTheme = .dark

    static func by(id: String) -> CalendarTheme {
        all.first(where: { $0.id == id }) ?? .default
    }
}
```

- [ ] **Step 2: Add file to Xcode project**

In Xcode: right-click `Screensavers` group → "New Group" named `Calendar` → drag `CalendarTheme.swift` into it (or Add Files). Make sure "WokyisScreensaver" target is checked.

- [ ] **Step 3: Build (⌘B) — expect success**

- [ ] **Step 4: Commit**

```bash
git add WokyisScreensaver/Screensavers/Calendar/CalendarTheme.swift
git commit -m "feat: add CalendarTheme dark/light tokens"
```

---

## Task 3: CalendarStore

**Files:**
- Create: `WokyisScreensaver/Screensavers/Calendar/CalendarStore.swift`

- [ ] **Step 1: Create CalendarStore.swift**

```swift
import Foundation
import EventKit
import Combine

enum CalendarAuthStatus {
    case notDetermined, authorized, denied
}

@MainActor
final class CalendarStore: ObservableObject {
    @Published private(set) var authStatus: CalendarAuthStatus = .notDetermined
    @Published private(set) var availableCalendars: [EKCalendar] = []
    @Published private(set) var events: [EKEvent] = []

    var selectedCalendarIDs: Set<String> {
        get { _selectedCalendarIDs }
        set { _selectedCalendarIDs = newValue; Task { await reload() } }
    }

    private var _selectedCalendarIDs: Set<String> = []
    private let store = EKEventStore()
    private var refreshTimer: Timer?
    private var notificationObserver: Any?

    init(selectedCalendarIDs: Set<String>) {
        self._selectedCalendarIDs = selectedCalendarIDs
        Task { await checkAuthAndLoad() }
        startTimer()
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in await self?.reload() }
        }
    }

    deinit {
        refreshTimer?.invalidate()
        if let obs = notificationObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    func requestAccess() async {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            authStatus = granted ? .authorized : .denied
            if granted { await reload() }
        } catch {
            authStatus = .denied
        }
    }

    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    func refresh() {
        Task { await reload() }
    }

    private func checkAuthAndLoad() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .authorized:
            authStatus = .authorized
            await reload()
        case .notDetermined:
            authStatus = .notDetermined
        default:
            authStatus = .denied
        }
    }

    private func reload() async {
        guard authStatus == .authorized else { return }
        let cals = store.calendars(for: .event)
        availableCalendars = cals
        let ids = _selectedCalendarIDs
        let filtered = ids.isEmpty ? cals : cals.filter { ids.contains($0.calendarIdentifier) }
        guard !filtered.isEmpty else { events = []; return }

        var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        startComponents.hour = 0; startComponents.minute = 0; startComponents.second = 0
        let start = Calendar.current.date(from: startComponents) ?? Date()
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: filtered)
        let fetched = store.events(matching: predicate)
        events = fetched
            .filter { event in
                guard let participants = event.attendees else { return true }
                let me = participants.first(where: { $0.isCurrentUser })
                return me?.participantStatus != .declined
            }
            .sorted { $0.startDate < $1.startDate }
    }

    private func startTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }
}
```

- [ ] **Step 2: Add file to Xcode project (Calendar group, target checked)**

- [ ] **Step 3: Build (⌘B) — expect success**

- [ ] **Step 4: Commit**

```bash
git add WokyisScreensaver/Screensavers/Calendar/CalendarStore.swift
git commit -m "feat: add CalendarStore with EventKit auth and event fetching"
```

---

## Task 4: CalendarPermissionView

**Files:**
- Create: `WokyisScreensaver/Screensavers/Calendar/CalendarPermissionView.swift`

- [ ] **Step 1: Create CalendarPermissionView.swift**

```swift
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
```

- [ ] **Step 2: Add file to Xcode project**

- [ ] **Step 3: Build (⌘B) — expect success**

- [ ] **Step 4: Commit**

```bash
git add WokyisScreensaver/Screensavers/Calendar/CalendarPermissionView.swift
git commit -m "feat: add CalendarPermissionView for EventKit auth states"
```

---

## Task 5: CalendarHeaderView

**Files:**
- Create: `WokyisScreensaver/Screensavers/Calendar/CalendarHeaderView.swift`

- [ ] **Step 1: Create CalendarHeaderView.swift**

```swift
import SwiftUI

struct CalendarHeaderView: View {
    let theme: CalendarTheme
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
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
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(theme.secondaryText)
                Text(dateFormatter.string(from: now))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
            }

            Spacer()

            Text(timeFormatter.string(from: now))
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(theme.primaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .onReceive(timer) { now = $0 }
    }
}
```

- [ ] **Step 2: Add file to Xcode project**

- [ ] **Step 3: Build (⌘B) — expect success**

- [ ] **Step 4: Commit**

```bash
git add WokyisScreensaver/Screensavers/Calendar/CalendarHeaderView.swift
git commit -m "feat: add CalendarHeaderView with live clock and today label"
```

---

## Task 6: TravelTimeBlockView + EventCardView

**Files:**
- Create: `WokyisScreensaver/Screensavers/Calendar/TravelTimeBlockView.swift`
- Create: `WokyisScreensaver/Screensavers/Calendar/EventCardView.swift`

- [ ] **Step 1: Create TravelTimeBlockView.swift**

```swift
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
```

- [ ] **Step 2: Create EventCardView.swift**

```swift
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
```

- [ ] **Step 3: Add both files to Xcode project**

- [ ] **Step 4: Build (⌘B) — expect success**

- [ ] **Step 5: Commit**

```bash
git add WokyisScreensaver/Screensavers/Calendar/TravelTimeBlockView.swift \
        WokyisScreensaver/Screensavers/Calendar/EventCardView.swift
git commit -m "feat: add EventCardView and TravelTimeBlockView"
```

---

## Task 7: TimelineView

**Files:**
- Create: `WokyisScreensaver/Screensavers/Calendar/TimelineView.swift`

The timeline shows hours 0–23 as rows. Each row is `hourHeight` points tall. Events are rendered as absolute-positioned overlays relative to midnight. A current-time indicator line is drawn at the proportional Y position for the current minute.

- [ ] **Step 1: Create TimelineView.swift**

```swift
import SwiftUI
import EventKit

private let hourHeight: CGFloat = 80
private let timeColumnWidth: CGFloat = 60

struct TimelineView: View {
    let events: [EKEvent]
    let theme: CalendarTheme

    @State private var now = Date()
    @State private var scrollProxy: ScrollViewProxy? = nil

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
                scrollProxy = proxy
                // Scroll to 2 hours before current time so current time is visible near top third
                let scrollHour = max(currentHour - 2, 0)
                proxy.scrollTo("hour_\(scrollHour)", anchor: .top)
            }
            .onReceive(timer) { now = $0 }
            .overlay(hourAnchorOverlay)
        }
    }

    // Invisible anchors for scrolling
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
```

- [ ] **Step 2: Add file to Xcode project**

- [ ] **Step 3: Build (⌘B) — expect success**

- [ ] **Step 4: Commit**

```bash
git add WokyisScreensaver/Screensavers/Calendar/TimelineView.swift
git commit -m "feat: add TimelineView with hour grid, events overlay and current-time indicator"
```

---

## Task 8: CalendarView (top-level)

**Files:**
- Create: `WokyisScreensaver/Screensavers/Calendar/CalendarView.swift`

- [ ] **Step 1: Create CalendarView.swift**

```swift
import SwiftUI

struct CalendarView: View {
    @ObservedObject var store: CalendarStore
    let theme: CalendarTheme

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            switch store.authStatus {
            case .notDetermined, .denied:
                CalendarPermissionView(
                    theme: theme,
                    authStatus: store.authStatus,
                    onRequestAccess: { Task { await store.requestAccess() } },
                    onOpenSettings: { store.openSystemSettings() }
                )
            case .authorized:
                VStack(spacing: 0) {
                    CalendarHeaderView(theme: theme)

                    Divider()
                        .background(theme.secondaryText.opacity(0.3))

                    if store.events.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(theme.secondaryText)
                            Text("No events today")
                                .font(.system(size: 16))
                                .foregroundStyle(theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        TimelineView(events: store.events, theme: theme)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Add file to Xcode project**

- [ ] **Step 3: Build (⌘B) — expect success**

- [ ] **Step 4: Commit**

```bash
git add WokyisScreensaver/Screensavers/Calendar/CalendarView.swift
git commit -m "feat: add CalendarView top-level switching permission/empty/timeline"
```

---

## Task 9: CalendarThemePicker + CalendarPicker

**Files:**
- Create: `WokyisScreensaver/Screensavers/Calendar/CalendarThemePicker.swift`
- Create: `WokyisScreensaver/Screensavers/Calendar/CalendarPicker.swift`

- [ ] **Step 1: Create CalendarThemePicker.swift**

Mirrors `FlipClockThemePicker` — shows dark/light swatches in a pill.

```swift
import SwiftUI

struct CalendarThemePicker: View {
    @Binding var selection: CalendarTheme
    var onLightBackground: Bool = false

    private var selectedFill: Color {
        onLightBackground ? Color.black.opacity(0.18) : Color.white.opacity(0.22)
    }
    private var unselectedFill: Color {
        onLightBackground ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
    }
    private var selectedStroke: Color { onLightBackground ? .black : .white }
    private var swatchStroke: Color {
        onLightBackground ? Color.black.opacity(0.25) : Color.white.opacity(0.25)
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(CalendarTheme.all) { theme in
                Button {
                    selection = theme
                } label: {
                    Circle()
                        .fill(theme.cardFill)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(swatchStroke, lineWidth: 0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(theme.id == selection.id ? selectedFill : unselectedFill)
                        )
                        .overlay(
                            Capsule()
                                .stroke(theme.id == selection.id ? selectedStroke : Color.clear, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
```

- [ ] **Step 2: Create CalendarPicker.swift**

Shows available calendars as toggle pills. Selecting none = show all.

```swift
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
```

- [ ] **Step 3: Add both files to Xcode project**

- [ ] **Step 4: Build (⌘B) — expect success**

- [ ] **Step 5: Commit**

```bash
git add WokyisScreensaver/Screensavers/Calendar/CalendarThemePicker.swift \
        WokyisScreensaver/Screensavers/Calendar/CalendarPicker.swift
git commit -m "feat: add CalendarThemePicker and CalendarPicker hover controls"
```

---

## Task 10: Wire up ContentView

**Files:**
- Modify: `WokyisScreensaver/App/ContentView.swift`

- [ ] **Step 1: Add CalendarStore state and AppStorage keys**

At the top of `ContentView`, add after the existing `@AppStorage` lines:

```swift
@AppStorage("calendarTheme")          private var calendarThemeRaw:  String = CalendarTheme.default.id
@AppStorage("calendarSelectedIDs")    private var calendarIDsRaw:    String = ""
@StateObject private var calendarStore: CalendarStore = CalendarStore(selectedCalendarIDs: [])
```

Add computed bindings after the existing `flipClockFont` binding:

```swift
private var calendarTheme: Binding<CalendarTheme> {
    Binding(
        get: { CalendarTheme.by(id: calendarThemeRaw) },
        set: { calendarThemeRaw = $0.id }
    )
}

private var calendarSelectedIDs: Binding<Set<String>> {
    Binding(
        get: {
            let ids = calendarIDsRaw.split(separator: ",").map(String.init)
            return Set(ids.filter { !$0.isEmpty })
        },
        set: { calendarIDsRaw = $0.sorted().joined(separator: ",") }
    )
}
```

- [ ] **Step 2: Update pickerOnLightBackground to handle .calendar**

Replace the existing `pickerOnLightBackground` computed property:

```swift
private var pickerOnLightBackground: Bool {
    switch selection.wrappedValue {
    case .flipClock: return flipClockTheme.wrappedValue.id == FlipClockTheme.light.id
    case .calendar:  return calendarTheme.wrappedValue.id == CalendarTheme.light.id
    default:         return false
    }
}
```

- [ ] **Step 3: Add .calendar branch to screensaverView**

In `screensaverView(for:)`, add before the closing `}`:

```swift
case .calendar:
    CalendarView(store: calendarStore, theme: calendarTheme.wrappedValue)
```

- [ ] **Step 4: Add calendar hover controls**

In the `VStack` body, after the existing `.flipClock` hover controls block, add:

```swift
if pickerVisible && selection.wrappedValue == .calendar {
    HStack(spacing: 8) {
        Button {
            calendarStore.refresh()
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(pickerOnLightBackground ? Color.black : Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)

        if !calendarStore.availableCalendars.isEmpty {
            CalendarPicker(
                calendars: calendarStore.availableCalendars,
                selectedIDs: calendarSelectedIDs,
                onLightBackground: pickerOnLightBackground
            )
        }

        CalendarThemePicker(
            selection: calendarTheme,
            onLightBackground: pickerOnLightBackground
        )
    }
    .padding(.bottom, 20)
    .transition(.opacity)
}
```

- [ ] **Step 5: Sync selectedCalendarIDs into store when the binding changes**

Add `.onChange` after the existing `.animation(...)` modifier:

```swift
.onChange(of: calendarIDsRaw) { _, newValue in
    let ids = newValue.split(separator: ",").map(String.init)
    calendarStore.selectedCalendarIDs = Set(ids.filter { !$0.isEmpty })
}
```

- [ ] **Step 6: Build (⌘B) — expect success**

- [ ] **Step 7: Commit**

```bash
git add WokyisScreensaver/App/ContentView.swift
git commit -m "feat: wire CalendarView, CalendarStore and hover controls into ContentView"
```

---

## Task 11: Smoke test the full flow

- [ ] **Step 1: Run the app in Xcode (⌘R)**

- [ ] **Step 2: Hover to show the picker, select "Calendar"**

Expected: permission prompt appears if Calendar access not yet granted.

- [ ] **Step 3: Grant access**

Click "Grant Access". Expected: permission prompt disappears, today's timeline appears.

- [ ] **Step 4: Verify timeline layout**

- Header shows "TODAY / [date]" on the left and current time on the right
- Time indicator line is at the current hour/minute position
- Scroll position shows current time near the top third of the visible area
- Events from your calendar appear as cards

- [ ] **Step 5: Test hover controls**

- Refresh button calls reload (no crash)
- Calendar pills toggle which calendars are shown
- Dark/Light swatch switches theme correctly

- [ ] **Step 6: Test denied state**

In System Settings → Privacy → Calendars, revoke access. Re-launch. Expected: "Open System Settings" button appears.

- [ ] **Step 7: Commit if any fixes were needed**

```bash
git add -p
git commit -m "fix: <description of any fix>"
```
