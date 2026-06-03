import SwiftUI
import WidgetKit

@Observable
final class MockDataStore {
    static let shared = MockDataStore()

    private let appGroup = "group.com.must.proptasistani"

    private init() {}

    func saveWidgetData(
        todayItems: [(clientName: String, initials: String, time: String, type: String)],
        ptInitials: String
    ) {
        struct Item: Codable { let clientName, clientInitials, time, type: String }
        guard let ud = UserDefaults(suiteName: appGroup) else { return }
        let items = todayItems.map {
            Item(clientName: $0.clientName, clientInitials: $0.initials, time: $0.time, type: $0.type)
        }
        if let data = try? JSONEncoder().encode(items) {
            ud.set(data, forKey: "widget_todayAppointments")
        }
        ud.set(ptInitials, forKey: "widget_ptInitials")
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadTimelines(ofKind: "ProPTWidget")
        }
    }
}
