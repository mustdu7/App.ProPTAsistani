import UserNotifications

@Observable
class NotificationManager {
    static let shared = NotificationManager()

    var isAuthorized: Bool = false

    init() {
        Task { await checkAuthorizationStatus() }
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { isAuthorized = granted }
        } catch { }
    }

    // MARK: - Schedule

    func scheduleNotification(
        id: String,
        clientName: String,
        date: Date,
        type: String,
        notify1h: Bool = true
    ) {
        guard isAuthorized else { return }
        let center = UNUserNotificationCenter.current()

        if notify1h {
            if let triggerDate = Calendar.current.date(byAdding: .hour, value: -1, to: date),
               triggerDate > Date() {
                let timeString = date.formatted(
                    .dateTime
                    .hour(.twoDigits(amPM: .omitted))
                    .minute(.twoDigits)
                    .locale(Locale(identifier: "tr_TR"))
                )
                let content = UNMutableNotificationContent()
                content.title = "1 saat sonra randevun var"
                content.body  = "\(clientName) · \(timeString) · \(type)"
                content.sound = .default
                content.userInfo = ["appointmentID": id]

                let comps = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(id)-1h",
                    content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    // MARK: - Cancel

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "\(id)-1h"
        ])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
