import SwiftData
import SwiftUI
import WidgetKit

@Observable
class DatabaseManager {
    static let shared = DatabaseManager()

    var clients:      [Client]      = []
    var appointments: [Appointment] = []
    var isLoading:    Bool          = false
    var lastError:    String?       = nil

    var modelContext: ModelContext?

    // MARK: - Setup

    func setup(context: ModelContext) {
        self.modelContext = context
        fetchClients()
        fetchAppointments()
    }

    // MARK: - Client CRUD

    func fetchClients() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Client>(sortBy: [SortDescriptor(\.name)])
            clients = try context.fetch(descriptor)
        } catch {
            lastError = "Müşteriler yüklenemedi: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func addClient(name: String, phone: String, totalSessions: Int) -> Client? {
        guard let context = modelContext else { return nil }
        let packageName: String
        switch totalSessions {
        case 0:    packageName = "Devamlı"
        case 1:    packageName = "Tek Ders"
        default:   packageName = "\(totalSessions)'li Paket"
        }

        let newClient = Client(
            name: name,
            phone: phone,
            totalSessions: totalSessions,
            remainingSessions: totalSessions,
            packageName: packageName
        )
        context.insert(newClient)
        save()
        fetchClients()
        return newClient
    }

    func updateClient(_ client: Client, name: String, phone: String) {
        client.name  = name
        client.phone = phone
        save()
        fetchClients()
    }

    func updateClientNotes(client: Client, notes: String) {
        client.notes = notes
        save()
        fetchClients()
    }

    func deleteClient(_ client: Client) {
        guard let context = modelContext else { return }
        context.delete(client)
        save()
        fetchClients()
        fetchAppointments()
    }

    func toggleClientActive(_ client: Client) {
        client.isActive.toggle()
        save()
        fetchClients()
    }

    // MARK: - Widget Sync

    func syncWidget() {
        let cal = Calendar.current
        let todayItems = appointments
            .filter { cal.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
            .map { appt -> (clientName: String, initials: String, time: String, type: String) in
                let initials = appt.clientName
                    .components(separatedBy: " ")
                    .compactMap { $0.first }
                    .prefix(2).map(String.init).joined()
                return (appt.clientName, initials, appt.timeString, appt.type)
            }
        MockDataStore.shared.saveWidgetData(
            todayItems: todayItems,
            ptInitials: AppSettings.shared.ptInitials
        )
    }

    // MARK: - Appointment CRUD

    func fetchAppointments() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Appointment>(sortBy: [SortDescriptor(\.date)])
            appointments = try context.fetch(descriptor)
            syncWidget()
        } catch {
            lastError = "Randevular yüklenemedi: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func addAppointment(
        client: Client,
        date: Date,
        durationMinutes: Int,
        type: String,
        notes: String = ""
    ) -> Appointment? {
        guard let context = modelContext else { return nil }

        // Çakışma kontrolü (1 saat içinde)
        let existing = appointments.filter { abs($0.date.timeIntervalSince(date)) < 3600 }
        if let conflict = existing.first {
            lastError = "Bu saatte zaten bir randevun var: \(conflict.clientName)"
            return nil
        }

        let appointment = Appointment(
            date: date,
            durationMinutes: durationMinutes,
            type: type,
            notes: notes,
            client: client
        )
        context.insert(appointment)
        save()
        fetchAppointments()
        return appointment
    }

    func saveRecurringAppointments(
        client: Client,
        startDate: Date,
        endDate: Date?,
        weekdays: Set<Int>,
        hour: Int,
        minute: Int,
        durationMinutes: Int,
        type: String,
        notes: String
    ) {
        guard let context = modelContext else { return }

        let calendar = Calendar.current
        let end = endDate ?? calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate

        var current = startDate
        var count   = 0

        while current <= end && count < 100 {
            let weekday = (calendar.component(.weekday, from: current) + 5) % 7
            if weekdays.contains(weekday) {
                var components      = calendar.dateComponents([.year, .month, .day], from: current)
                components.hour     = hour
                components.minute   = minute
                components.timeZone = TimeZone.current
                if let aptDate = calendar.date(from: components), aptDate > Date() {
                    let appointment = Appointment(
                        date: aptDate,
                        durationMinutes: durationMinutes,
                        type: type,
                        notes: notes,
                        client: client
                    )
                    context.insert(appointment)
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
            count += 1
        }

        save()
        fetchAppointments()
    }

    func deleteAppointment(_ appointment: Appointment) {
        guard let context = modelContext else { return }
        context.delete(appointment)
        save()
        fetchAppointments()
    }

    func markCompleted(_ appointment: Appointment) {
        guard !appointment.isCompleted else { return }
        appointment.isCompleted = true

        // Müşterinin kalan seansını azalt
        if let client = appointment.client, client.remainingSessions > 0 {
            client.remainingSessions -= 1
        }

        save()
        fetchAppointments()
        fetchClients()
    }

    func updateAppointment(_ appointment: Appointment, date: Date, durationMinutes: Int, type: String, notes: String) {
        appointment.date            = date
        appointment.durationMinutes = durationMinutes
        appointment.type            = type
        appointment.notes           = notes
        save()
        fetchAppointments()
    }

    // MARK: - Delete All Data

    func deleteAllData() {
        guard let context = modelContext else { return }
        do {
            let allAppointments = try context.fetch(FetchDescriptor<Appointment>())
            for apt in allAppointments { context.delete(apt) }
            let allClients = try context.fetch(FetchDescriptor<Client>())
            for client in allClients { context.delete(client) }
            save()
            clients = []
            appointments = []
            syncWidget()
        } catch {
            lastError = "Veriler silinemedi: \(error.localizedDescription)"
        }
    }

    // MARK: - Private

    private func save() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            lastError = "Kayıt hatası: \(error.localizedDescription)"
        }
    }
}
