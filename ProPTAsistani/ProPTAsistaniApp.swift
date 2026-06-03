import SwiftUI
import SwiftData
import GoogleMobileAds
import AppTrackingTransparency

@main
struct ProPTAsistaniApp: App {
    @State private var settings = AppSettings.shared

    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if settings.hasSeenWelcome {
                    ContentView()
                } else {
                    WelcomeView()
                }
            }
            .onAppear {
                Task {
                    await NotificationManager.shared.requestAuthorization()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    ATTrackingManager.requestTrackingAuthorization { _ in }
                }
            }
            .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Client.self, Appointment.self])
    }
}
