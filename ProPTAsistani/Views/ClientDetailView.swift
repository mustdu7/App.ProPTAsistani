import SwiftUI

struct ClientDetailView: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @State private var db = DatabaseManager.shared

    @State private var isEditing: Bool = false
    @State private var editName: String = ""
    @State private var editPhone: String = ""
    @State private var showAddAppointment: Bool = false

    // Notlar
    @State private var isEditingNotes: Bool = false
    @State private var notesText: String = ""

    private var clientAppointments: [Appointment] {
        db.appointments
            .filter { $0.client?.id == client.id }
            .sorted { $0.date > $1.date }
    }

    private var currentClient: Client {
        db.clients.first { $0.id == client.id } ?? client
    }

    private var isDevamli: Bool { currentClient.totalSessions == 0 }

    private var totalCount: Int {
        isDevamli ? clientAppointments.count : currentClient.totalSessions
    }

    private var completedCount: Int {
        isDevamli
            ? clientAppointments.filter { $0.isCompleted }.count
            : currentClient.totalSessions - currentClient.remainingSessions
    }

    private var remainingCount: Int {
        isDevamli
            ? clientAppointments.filter { !$0.isCompleted }.count
            : currentClient.remainingSessions
    }

    private var progressColor: Color {
        if isDevamli { return Color(hex: "#F5F4F0") }
        if currentClient.remainingSessions == 0 { return Color(hex: "#E05C5C") }
        if currentClient.remainingSessions <= 2  { return Color(hex: "#F0A500") }
        return Color(hex: "#F5F4F0")
    }

    private var lastSessionText: String {
        let past = clientAppointments.filter { $0.isPast }
        guard let last = past.first else { return "Henüz yok" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "tr_TR")
        fmt.dateFormat = "d MMM"
        return fmt.string(from: last.date)
    }

    private func formattedDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Bugün" }
        if cal.isDateInTomorrow(date)  { return "Yarın" }
        if cal.isDateInYesterday(date) { return "Dün" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "tr_TR")
        fmt.dateFormat = "d MMM"
        return fmt.string(from: date)
    }

    var body: some View {
        ZStack {
            Color(hex: "#141416").ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                HStack(spacing: 14) {
                    Text(currentClient.initials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: "#F5F4F0"))
                        .frame(width: 52, height: 52)
                        .background(Color(hex: "#2C2C2E"))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentClient.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(hex: "#F5F4F0"))

                        HStack(spacing: 8) {
                            Text(currentClient.packageName)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#A09FA6"))

                            Text(currentClient.isActive ? "Aktif" : "Pasif")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(currentClient.isActive ? Color(hex: "#4CAF50") : Color(hex: "#4A4A55"))
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(currentClient.isActive ? Color(hex: "#1A2A1A") : Color(hex: "#2A2A2A"))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    Spacer()

                    if !isEditing {
                        Button {
                            editName  = currentClient.name
                            editPhone = currentClient.phone
                            isEditing = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color(hex: "#3A3A3C"))
                        }
                        .buttonStyle(.plain)
                    }

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(hex: "#3A3A3C"))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                Rectangle().fill(Color(hex: "#2A2A2D")).frame(height: 0.5)

                ScrollView {
                    VStack(spacing: 14) {
                        // MARK: Düzenleme formu
                        if isEditing {
                            VStack(spacing: 10) {
                                TextField("Ad Soyad", text: $editName)
                                    .font(.system(size: 15)).foregroundStyle(Color(hex: "#F5F4F0"))
                                    .tint(Color(hex: "#F5F4F0"))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.words)
                                    .padding(12)
                                    .background(Color(hex: "#2C2C2E"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                TextField("Telefon", text: $editPhone)
                                    .font(.system(size: 15)).foregroundStyle(Color(hex: "#F5F4F0"))
                                    .tint(Color(hex: "#F5F4F0"))
                                    .keyboardType(.phonePad)
                                    .padding(12)
                                    .background(Color(hex: "#2C2C2E"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                HStack(spacing: 10) {
                                    Button {
                                        let trimmed = editName.trimmingCharacters(in: .whitespaces)
                                        guard trimmed.count >= 2 else { return }
                                        db.updateClient(currentClient, name: trimmed, phone: editPhone)
                                        isEditing = false
                                    } label: {
                                        Text("Kaydet")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#141416"))
                                            .frame(maxWidth: .infinity).frame(height: 40)
                                            .background(Color(hex: "#F5F4F0"))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        db.deleteClient(currentClient)
                                        dismiss()
                                    } label: {
                                        Text("Müşteriyi Sil")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#E05C5C"))
                                            .frame(maxWidth: .infinity).frame(height: 40)
                                            .background(Color(hex: "#E05C5C").opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#E05C5C").opacity(0.3), lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)

                                    Button { isEditing = false } label: {
                                        Text("İptal")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Color(hex: "#A09FA6"))
                                            .frame(height: 40)
                                            .padding(.horizontal, 16)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                            .background(Color(hex: "#1E1E22"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }

                        // MARK: Stat Kartlar
                        HStack(spacing: 8) {
                            StatCard(
                                label: "Tamamlandı",
                                value: "\(completedCount)",
                                sub: "/\(totalCount) ders",
                                valueColor: Color(hex: "#F5F4F0")
                            )
                            StatCard(
                                label: "Kalan",
                                value: "\(remainingCount)",
                                sub: "ders",
                                valueColor: progressColor
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, isEditing ? 0 : 16)

                        Button {
                            showAddAppointment = true
                        } label: {
                            Text("Randevu Ekle")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: "#141416"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color(hex: "#F5F4F0"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        Button {
                            db.toggleClientActive(currentClient)
                        } label: {
                            Text(currentClient.isActive ? "Pasife Al" : "Aktife Al")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "#F0A500"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color(hex: "#F0A500").opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#F0A500").opacity(0.3), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        // MARK: İletişim
                        if !currentClient.phone.isEmpty {
                            SectionView(title: "İLETİŞİM") {
                                let digits = currentClient.phone.filter { $0.isNumber }
                                if let telURL = URL(string: "tel:\(digits)") {
                                    Link(destination: telURL) {
                                        HStack {
                                            Image(systemName: "phone.fill")
                                                .font(.system(size: 14)).foregroundStyle(Color(hex: "#F5F4F0")).frame(width: 20)
                                            Text(currentClient.phone)
                                                .font(.system(size: 15)).foregroundStyle(Color(hex: "#F5F4F0"))
                                            Spacer()
                                            Image(systemName: "phone.circle.fill")
                                                .font(.system(size: 24)).foregroundStyle(Color(hex: "#F5F4F0"))
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 14)
                                    }
                                }
                            }
                        }

                        // MARK: Notlar
                        SectionView(title: "NOTLAR") {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Spacer()
                                    Button {
                                        if isEditingNotes {
                                            db.updateClientNotes(client: currentClient, notes: notesText)
                                            isEditingNotes = false
                                        } else {
                                            notesText = currentClient.notes
                                            isEditingNotes = true
                                        }
                                    } label: {
                                        Text(isEditingNotes ? "Kaydet" : "Düzenle")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#A09FA6"))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 14).padding(.top, 10)

                                if isEditingNotes {
                                    TextEditor(text: $notesText)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "#F5F4F0"))
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .frame(minHeight: 80)
                                        .padding(.horizontal, 10)
                                        .padding(.bottom, 10)
                                } else {
                                    Text(currentClient.notes.isEmpty ? "Not eklenmedi" : currentClient.notes)
                                        .font(.system(size: 14))
                                        .foregroundStyle(currentClient.notes.isEmpty ? Color(hex: "#4A4A55") : Color(hex: "#F5F4F0"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 14).padding(.bottom, 14)
                                }
                            }
                        }

                        // MARK: Son Randevular
                        SectionView(title: "SON RANDEVULAR") {
                            if clientAppointments.isEmpty {
                                Text("Henüz randevu yok")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: "#4A4A55"))
                                    .padding(.horizontal, 14).padding(.vertical, 16)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(clientAppointments.enumerated()), id: \.element.id) { index, appt in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(formattedDate(appt.date)) · \(appt.timeString)")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundStyle(Color(hex: "#F5F4F0"))
                                                Text(appt.type)
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(Color(hex: "#A09FA6"))
                                            }
                                            Spacer()
                                            if appt.isPast {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundStyle(Color(hex: "#4CAF50"))
                                            } else {
                                                Image(systemName: "clock")
                                                    .font(.system(size: 18))
                                                    .foregroundStyle(Color(hex: "#A09FA6"))
                                            }
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 12)

                                        if index < clientAppointments.count - 1 {
                                            Rectangle().fill(Color(hex: "#2A2A2D")).frame(height: 0.5).padding(.horizontal, 14)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Hata", isPresented: Binding(
            get: { db.lastError != nil },
            set: { if !$0 { db.lastError = nil } }
        )) {
            Button("Tamam") { db.lastError = nil }
        } message: {
            Text(db.lastError ?? "")
        }
        .onAppear {
            db.fetchAppointments()
            db.fetchClients()
        }
        .fullScreenCover(isPresented: $showAddAppointment) {
            NewAppointmentView(preselectedClient: client)
        }
    }
}

// MARK: - Stat Card
private struct StatCard: View {
    let label: String
    let value: String
    let sub: String
    let valueColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 11)).foregroundStyle(Color(hex: "#A09FA6"))
            Text(value).font(.system(size: 20, weight: .semibold)).foregroundStyle(valueColor).lineLimit(1).minimumScaleFactor(0.7)
            Text(sub.isEmpty ? " " : sub).font(.system(size: 11)).foregroundStyle(Color(hex: "#A09FA6"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: "#1E1E22"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
    }
}

// MARK: - Section View
private struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(hex: "#A09FA6"))
                .padding(.horizontal, 20).padding(.bottom, 6)
            VStack(spacing: 0) { content }
                .background(Color(hex: "#1E1E22"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
                .padding(.horizontal, 16)
        }
    }
}
