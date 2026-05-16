import SwiftUI

struct EditAppointmentView: View {
    let appointment: Appointment
    @Environment(\.dismiss) var dismiss
    @State private var db = DatabaseManager.shared

    @State private var selectedDate: Date
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var selectedType: String
    @State private var duration: Int
    @State private var note: String
    @State private var showTimePicker = false
    @State private var isSaving = false

    let types = ["Güç Antrenmanı", "Kardio", "Fonksiyonel", "Pilates", "Esneklik", "HIIT"]
    let durations = [30, 45, 60, 75, 90]

    init(appointment: Appointment) {
        self.appointment = appointment
        _selectedDate   = State(initialValue: appointment.date)
        _selectedHour   = State(initialValue: Calendar.current.component(.hour,   from: appointment.date))
        _selectedMinute = State(initialValue: Calendar.current.component(.minute, from: appointment.date))
        _selectedType   = State(initialValue: appointment.type)
        _duration       = State(initialValue: appointment.durationMinutes)
        _note           = State(initialValue: appointment.notes)
    }

    var body: some View {
        ZStack {
            Color(hex: "#141416").ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    Button("İptal") { dismiss() }
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#A09FA6"))

                    Spacer()

                    Text("Randevuyu Düzenle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: "#F5F4F0"))

                    Spacer()

                    Button("Kaydet") { saveChanges() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "#F5F4F0"))
                        .opacity(isSaving ? 0.4 : 1.0)
                        .disabled(isSaving)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                ThinDivider()

                // MARK: Müşteri satırı
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#2C2C2E"))
                            .frame(width: 32, height: 32)
                        Text(appointment.clientName
                            .components(separatedBy: " ")
                            .compactMap { $0.first }
                            .prefix(2)
                            .map(String.init)
                            .joined())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "#F5F4F0"))
                    }
                    Text(appointment.clientName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#F5F4F0"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "#1E1E22"))

                ThinDivider()

                ScrollView {
                    VStack(spacing: 16) {

                        // MARK: Tarih ve Saat
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TARİH VE SAAT")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "#A09FA6"))
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                // Tarih
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "#F5F4F0"))
                                        .frame(width: 20)
                                    Text("Tarih")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color(hex: "#A09FA6"))
                                    Spacer()
                                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .environment(\.locale, Locale(identifier: "tr_TR"))
                                        .tint(Color(hex: "#F5F4F0"))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                                ThinDivider().padding(.horizontal, 14)

                                // Saat
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "#F5F4F0"))
                                        .frame(width: 20)
                                    Text("Saat")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color(hex: "#A09FA6"))
                                    Spacer()
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) { showTimePicker.toggle() }
                                    } label: {
                                        Text(String(format: "%02d:%02d", selectedHour, selectedMinute))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Color(hex: "#F5F4F0"))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color(hex: "#2C2C2E"))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                                if showTimePicker {
                                    VStack(spacing: 8) {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 6) {
                                                ForEach(6...22, id: \.self) { hour in
                                                    Text(String(format: "%02d", hour))
                                                        .font(.system(size: 13, weight: selectedHour == hour ? .semibold : .regular))
                                                        .foregroundStyle(selectedHour == hour ? Color(hex: "#141416") : Color(hex: "#A09FA6"))
                                                        .frame(width: 44, height: 30)
                                                        .background(selectedHour == hour ? Color(hex: "#F5F4F0") : Color(hex: "#2C2C2E"))
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                        .onTapGesture {
                                                            withAnimation(.spring(response: 0.2)) { selectedHour = hour }
                                                        }
                                                }
                                            }
                                            .padding(.horizontal, 14)
                                        }

                                        HStack(spacing: 6) {
                                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                                Text(String(format: ":%02d", minute))
                                                    .font(.system(size: 13, weight: selectedMinute == minute ? .semibold : .regular))
                                                    .foregroundStyle(selectedMinute == minute ? Color(hex: "#141416") : Color(hex: "#A09FA6"))
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 30)
                                                    .background(selectedMinute == minute ? Color(hex: "#F5F4F0") : Color(hex: "#2C2C2E"))
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                                    .onTapGesture {
                                                        withAnimation(.spring(response: 0.2)) { selectedMinute = minute }
                                                    }
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                    }
                                    .padding(.vertical, 8)
                                    .transition(.opacity)
                                }
                            }
                            .styledCard()
                            .padding(.horizontal, 16)
                        }

                        // MARK: Antrenman
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ANTRENMAN")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "#A09FA6"))
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color(hex: "#F5F4F0"))
                                            .frame(width: 20)
                                        Text("Antrenman Türü")
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color(hex: "#A09FA6"))
                                    }
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(types, id: \.self) { t in
                                                Text(t)
                                                    .font(.system(size: 13))
                                                    .foregroundStyle(selectedType == t ? Color(hex: "#141416") : Color(hex: "#A09FA6"))
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 8)
                                                    .background(selectedType == t ? Color(hex: "#F5F4F0") : Color(hex: "#2C2C2E"))
                                                    .clipShape(Capsule())
                                                    .onTapGesture { selectedType = t }
                                            }
                                        }
                                    }
                                }
                                .padding(14)

                                ThinDivider().padding(.horizontal, 14)

                                HStack {
                                    Image(systemName: "timer")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "#F5F4F0"))
                                        .frame(width: 20)
                                    Text("Süre")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color(hex: "#A09FA6"))
                                    Spacer()
                                    HStack(spacing: 14) {
                                        Button {
                                            if let idx = durations.firstIndex(of: duration), idx > 0 {
                                                duration = durations[idx - 1]
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundStyle(Color(hex: "#F5F4F0"))
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(duration == durations.first)

                                        Text("\(duration) dk")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#F5F4F0"))
                                            .frame(minWidth: 52, alignment: .center)

                                        Button {
                                            if let idx = durations.firstIndex(of: duration), idx < durations.count - 1 {
                                                duration = durations[idx + 1]
                                            }
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundStyle(Color(hex: "#F5F4F0"))
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(duration == durations.last)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            }
                            .styledCard()
                            .padding(.horizontal, 16)
                        }

                        // MARK: Not
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOT (OPSİYONEL)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "#A09FA6"))
                                .padding(.horizontal, 16)

                            ZStack(alignment: .topLeading) {
                                if note.isEmpty {
                                    Text("Antrenman notu, özel talimatlar...")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "#4A4A55"))
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 18)
                                }
                                TextEditor(text: $note)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: "#F5F4F0"))
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .frame(minHeight: 80)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                            }
                            .styledCard()
                            .padding(.horizontal, 16)
                        }

                        // MARK: Kaydet butonu
                        Button { saveChanges() } label: {
                            Text("Değişiklikleri Kaydet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(hex: "#141416"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hex: "#F5F4F0"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .opacity(isSaving ? 0.4 : 1.0)
                        .disabled(isSaving)
                    }
                    .padding(.top, 16)
                }
                .scrollBounceBehavior(.always)
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
    }

    private func saveChanges() {
        isSaving = true
        var comps       = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        comps.hour      = selectedHour
        comps.minute    = selectedMinute
        let newDate     = Calendar.current.date(from: comps) ?? selectedDate

        db.updateAppointment(appointment, date: newDate, durationMinutes: duration, type: selectedType, notes: note)

        let aptId = appointment.id.uuidString
        NotificationManager.shared.cancelNotification(id: aptId)
        let notify1h = UserDefaults.standard.object(forKey: "notify1h") as? Bool ?? true
        NotificationManager.shared.scheduleNotification(
            id:         aptId,
            clientName: appointment.clientName,
            date:       newDate,
            type:       selectedType,
            notify1h:   notify1h
        )
        isSaving = false
        dismiss()
    }
}
