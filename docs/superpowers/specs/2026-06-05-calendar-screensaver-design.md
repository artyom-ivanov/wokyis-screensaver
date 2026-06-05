# Calendar Screensaver — Design Spec

Date: 2026-06-05

## Overview

A new screensaver mode showing today's calendar agenda with a live clock. Two color themes (dark/light). Calendar access is requested inline when not granted.

## Architecture

### CalendarStore

`CalendarStore: ObservableObject` owns all EventKit interaction.

**Published state:**
- `events: [EKEvent]` — today's events (declined excluded), filtered by selected calendars
- `calendars: [EKCalendar]` — all available event calendars
- `selectedCalendarIDs: Set<String>` — persisted via `AppStorage`
- `authStatus: AuthStatus` — enum: `notDetermined`, `authorized`, `denied`

**Update triggers:**
- `EKEventStore.default` change notification → reload
- `Timer` every 5 minutes → reload
- `refresh()` method → immediate reload (called from hover button)

**EventKit API:**
- macOS 14+: `requestFullAccessToEvents()`
- macOS 13 and earlier: `requestAccess(to: .event)`
- Denied state: open System Settings via `NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)`

**Filtering:**
- Exclude events where `EKParticipant.participantStatus == .declined` for the current user
- Only show events from `selectedCalendarIDs`
- Reload events for today (midnight to midnight, local timezone)

### CalendarView

`CalendarView` receives `@ObservedObject store: CalendarStore`. Three rendering states:

1. **Permission state** (`notDetermined` or `denied`) — centered permission prompt
2. **Empty/loading** — spinner or empty state message
3. **Timeline** — full agenda view

### Integration into existing app

- Add `.calendar` case to `ScreensaverID`
- `CalendarStore` instantiated as `@StateObject` in `ContentView`, shared with `CalendarView`
- Hover panel for `.calendar` adds:
  - `CalendarThemePicker` (dark/light toggle, same pattern as `FlipClockThemePicker`)
  - `CalendarPicker` (multi-select list of available calendars)
  - Refresh button (calls `store.refresh()`)
- `AppStorage` keys: `calendarTheme`, `selectedCalendarIDs`

## Timeline View Layout

### Header (always visible, above scroll area)
- Left: "TODAY" in small caps + "Fri 5 Jun" larger below
- Right: current time, large font (updates every second via `Timer`)
- Separator line below header

### Scroll area
- Vertical `ScrollView`, scrolled to current time on appear and when screensaver is re-shown
- Time column on the left (hour labels, e.g. "6:00 PM")
- Event cards on the right
- Current time indicator: horizontal line spanning full width, with time label on the left (same as reference screenshot)

### Event cards
- Title, time range, location (if set), RSVP icon + status text
- Travel time block rendered **above** the event card (same as native Calendar.app), using `EKEvent.structuredLocation` travel time data from EventKit
- Border style: solid for `Going`, dashed/dotted for `Maybe` and `No reply`
- Declined events hidden

### Color themes

| Element | Dark | Light |
|---|---|---|
| Background | `#0a0a0a` | `#f5f5f5` |
| Card fill | `#1c1c1c` | `#ffffff` |
| Primary text | `#ffffff` | `#000000` |
| Secondary text | `#8e8e93` | `#6c6c70` |
| Time indicator | `#ffffff` | `#000000` |

## Permission Screen

Shown when `authStatus` is `.notDetermined` or `.denied`. Centered in the screensaver frame.

- SF Symbol: `calendar` (large)
- Title: "Calendar Access Required"
- Body: "Wokyis needs access to your calendars to display your agenda."
- Button: "Grant Access"
  - If `notDetermined`: calls `requestFullAccessToEvents()` / `requestAccess(to:)`
  - If `denied`: opens System Settings Privacy → Calendars
- Follows dark/light theme

## New Files

- `WokyisScreensaver/Calendar/CalendarStore.swift`
- `WokyisScreensaver/Calendar/CalendarView.swift`
- `WokyisScreensaver/Calendar/CalendarTheme.swift`
- `WokyisScreensaver/Calendar/CalendarPicker.swift` (calendar multi-select hover panel)
- `WokyisScreensaver/Calendar/CalendarThemePicker.swift`

## Modified Files

- `ScreensaverID.swift` — add `.calendar` case
- `ContentView.swift` — add `.calendar` branch in `screensaverView`, add hover controls
- `Info.plist` — add `NSCalendarsFullAccessUsageDescription`

## Out of Scope

- Multi-day view
- Event creation or editing
- Notifications
- Travel time calculated from current location (use stored EventKit data only)
