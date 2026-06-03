import SwiftData
import Foundation

@Model
final class Client: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var phone: String
    var totalSessions: Int
    var remainingSessions: Int
    var packageName: String
    var isActive: Bool
    var createdAt: Date
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \Appointment.client)
    var appointments: [Appointment] = []

    init(
        name: String,
        phone: String = "",
        totalSessions: Int,
        remainingSessions: Int,
        packageName: String,
        isActive: Bool = true,
        createdAt: Date = Date(),
        notes: String = ""
    ) {
        self.name              = name
        self.phone             = phone
        self.totalSessions     = totalSessions
        self.remainingSessions = remainingSessions
        self.packageName       = packageName
        self.isActive          = isActive
        self.createdAt         = createdAt
        self.notes             = notes
    }

    var initials: String {
        name.components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
}
