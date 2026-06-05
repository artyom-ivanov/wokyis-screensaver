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
