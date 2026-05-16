import SwiftUI
import UserNotifications

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var hasSeenWelcome: Bool      { didSet { save("hasSeenWelcome", hasSeenWelcome) } }
    var ptName: String            { didSet { save("ptName", ptName) } }
    var notificationsEnabled: Bool { didSet {
        save("notificationsEnabled", notificationsEnabled)
        if notificationsEnabled { requestPermission() }
        else { UNUserNotificationCenter.current().removeAllPendingNotificationRequests() }
    }}
    var notify1h: Bool            { didSet { save("notify1h", notify1h) } }
    var fontSize: String          { didSet { save("fontSize", fontSize) } }
    var weekStart: String         { didSet { save("weekStart", weekStart) } }

    private init() {
        let ud = UserDefaults.standard
        hasSeenWelcome      = ud.bool(forKey: "hasSeenWelcome")
        ptName              = ud.string(forKey: "ptName")          ?? ""
        notificationsEnabled = ud.object(forKey: "notificationsEnabled") as? Bool ?? true
        notify1h            = ud.object(forKey: "notify1h")        as? Bool ?? true
        fontSize            = ud.string(forKey: "fontSize")        ?? "O"
        weekStart           = ud.string(forKey: "weekStart")       ?? "Pzt"
    }

    // MARK: - Helpers

    var ptInitials: String {
        let name = ptName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return "PT" }
        let parts = name.components(separatedBy: " ").filter { !$0.isEmpty }
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    var weekStartsOnMonday: Bool { weekStart == "Pzt" }

    var dayLabels: [String] {
        weekStartsOnMonday
            ? ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]
            : ["Pz", "Pt", "Sa", "Ça", "Pe", "Cu", "Ct"]
    }

    func firstWeekdayOffset(for date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        // weekday: 1=Sun 2=Mon … 7=Sat
        if weekStartsOnMonday {
            return (weekday + 5) % 7   // Mon=0 … Sun=6
        } else {
            return weekday - 1         // Sun=0 … Sat=6
        }
    }

    // MARK: - Notifications

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Private

    private func save(_ key: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
