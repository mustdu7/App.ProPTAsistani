import SwiftData
import Foundation

@Model
final class Appointment: Identifiable, AppointmentDisplaying {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var durationMinutes: Int
    var type: String
    var notes: String
    var isCompleted: Bool

    var client: Client?

    init(
        date: Date,
        durationMinutes: Int,
        type: String,
        notes: String = "",
        isCompleted: Bool = false,
        client: Client? = nil
    ) {
        self.date            = date
        self.durationMinutes = durationMinutes
        self.type            = type
        self.notes           = notes
        self.isCompleted     = isCompleted
        self.client          = client
    }

    var clientName: String {
        client?.name ?? "Bilinmiyor"
    }

    var durationString: String {
        "\(durationMinutes) dk"
    }

    var isPast: Bool {
        isCompleted || date < Date()
    }

    var timeString: String {
        date.formatted(
            .dateTime
            .hour(.twoDigits(amPM: .omitted))
            .minute(.twoDigits)
            .locale(Locale(identifier: "tr_TR"))
        )
    }
}
