import SwiftUI

// MARK: - Models
enum AppointmentMode { case single, recurring }

struct RecurringSlot: Identifiable, Equatable {
    let id = UUID()
    var date: Date
    var hour: Int = 9
    var minute: Int = 0
}

// MARK: - NewAppointmentView
struct NewAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var db = DatabaseManager.shared

    var preselectedClient: Client? = nil

    // Step
    @State private var currentStep: Int = 1

    // Step 1
    @State private var selectedClient: Client? = nil
    @State private var searchText: String = ""
    @State private var showNewClientInline: Bool = false
    @State private var newClientName: String = ""
    @State private var newClientPhone: String = ""

    // Step 2
    @State private var appointmentMode: AppointmentMode = .single
    @State private var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var showDatePicker: Bool = true
    @State private var singleCalendarMonth: Date = Date()
    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0
    @State private var showTimePicker: Bool = false
    @State private var selectedType: String = "Güç Antrenmanı"
    @State private var duration: Int = 60
    @State private var note: String = ""

    // Telefon validasyonu
    @State private var phoneFieldTouched: Bool = false

    // Recurring — yeni takvim tabanlı
    @State private var recurringSessionCount: Int = 2
    @State private var recurringSlots: [RecurringSlot] = []
    @State private var recurringCalendarMonth: Date = Date()
    @State private var expandedSlotId: UUID? = nil
    @State private var editingHour: Int = 9
    @State private var editingMinute: Int = 0

    private let trainingTypes = ["Güç Antrenmanı", "Kardio", "Fonksiyonel", "Pilates", "Esneklik", "HIIT"]
    private let durationSteps = [30, 45, 60, 75, 90]

    private var filteredClients: [Client] {
        searchText.isEmpty ? db.clients : db.clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func isValidPhone(_ phone: String) -> Bool {
        if phone.isEmpty { return true }
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
        return cleaned.hasPrefix("05") && cleaned.count == 11 && cleaned.allSatisfy { $0.isNumber }
    }

    private func advanceToStep2(sessions: Int) {
        appointmentMode = .single
        withAnimation(.easeInOut(duration: 0.25)) { currentStep = 2 }
    }

    private var step2Valid: Bool {
        switch appointmentMode {
        case .single:
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            comps.hour = selectedHour
            comps.minute = selectedMinute
            let aptDate = Calendar.current.date(from: comps) ?? selectedDate
            return aptDate > Date()
        case .recurring:
            return recurringSlots.count == recurringSessionCount
        }
    }

    private var step2ValidationMessage: String? {
        switch appointmentMode {
        case .single:
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            comps.hour = selectedHour
            comps.minute = selectedMinute
            let aptDate = Calendar.current.date(from: comps) ?? selectedDate
            return aptDate <= Date() ? "Geçmiş bir tarih/saat seçildi" : nil
        case .recurring:
            return nil
        }
    }

    private func saveAndDismiss() {
        guard let clientModel = selectedClient else { return }
        let notify1h = UserDefaults.standard.object(forKey: "notify1h") as? Bool ?? true

        switch appointmentMode {
        case .single:
            var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            components.hour = selectedHour
            components.minute = selectedMinute
            let aptDate = Calendar.current.date(from: components) ?? selectedDate

            if let apt = db.addAppointment(
                client: clientModel,
                date: aptDate,
                durationMinutes: duration,
                type: selectedType,
                notes: note
            ) {
                NotificationManager.shared.scheduleNotification(
                    id: apt.id.uuidString,
                    clientName: clientModel.name,
                    date: aptDate,
                    type: selectedType,
                    notify1h: notify1h
                )
            }

        case .recurring:
            for slot in recurringSlots {
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: slot.date)
                comps.hour = slot.hour
                comps.minute = slot.minute
                let aptDate = Calendar.current.date(from: comps) ?? slot.date

                if let apt = db.addAppointment(
                    client: clientModel,
                    date: aptDate,
                    durationMinutes: duration,
                    type: selectedType,
                    notes: note
                ) {
                    NotificationManager.shared.scheduleNotification(
                        id: apt.id.uuidString,
                        clientName: clientModel.name,
                        date: aptDate,
                        type: selectedType,
                        notify1h: notify1h
                    )
                }
            }
        }
        dismiss()
    }

    var body: some View {
        ZStack {
            Color(hex: "#141416").ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    if currentStep == 1 {
                        Button("İptal") { dismiss() }
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: "#A09FA6"))
                    } else {
                        if preselectedClient != nil {
                            Button("İptal") { dismiss() }
                                .font(.system(size: 15))
                                .foregroundStyle(Color(hex: "#A09FA6"))
                        } else {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) { currentStep = 1 }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .medium))
                                    Text("Geri").font(.system(size: 15))
                                }
                                .foregroundStyle(Color(hex: "#A09FA6"))
                            }
                        }
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Circle()
                            .fill(currentStep >= 1 ? Color(hex: "#F5F4F0") : Color(hex: "#3A3A3C"))
                            .frame(width: 8, height: 8)
                        Rectangle()
                            .fill(currentStep == 2 ? Color(hex: "#F5F4F0") : Color(hex: "#3A3A3C"))
                            .frame(width: 32, height: 1)
                        Circle()
                            .fill(currentStep == 2 ? Color(hex: "#F5F4F0") : Color(hex: "#3A3A3C"))
                            .frame(width: 8, height: 8)
                    }

                    Spacer()

                    if currentStep == 1 {
                        Button {
                            guard let client = selectedClient else { return }
                            advanceToStep2(sessions: client.remainingSessions)
                        } label: {
                            Text("İleri")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: "#F5F4F0"))
                        }
                        .opacity(selectedClient != nil ? 1.0 : 0.4)
                        .disabled(selectedClient == nil)
                    } else {
                        Button("Kaydet") { saveAndDismiss() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: "#F5F4F0"))
                            .opacity(step2Valid ? 1.0 : 0.4)
                            .disabled(!step2Valid)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                ThinDivider()

                if currentStep == 1 {
                    step1View
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .leading)
                        ))
                } else {
                    step2View
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                }
            }
        }
        .alert("Hata", isPresented: Binding(
            get: { db.lastError != nil },
            set: { if !$0 { db.lastError = nil } }
        )) {
            Button("Tamam") { db.lastError = nil }
        } message: {
            Text(db.lastError ?? "")
        }
        .onAppear {
            db.fetchClients()
            if let client = preselectedClient {
                selectedClient = client
                advanceToStep2(sessions: client.remainingSessions)
            }
        }
    }

    // MARK: - Adım 1: Kim
    private var step1View: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14)).foregroundStyle(Color(hex: "#A09FA6"))
                    TextField("İsim ara...", text: $searchText)
                        .font(.system(size: 15)).foregroundStyle(Color(hex: "#F5F4F0"))
                        .tint(Color(hex: "#F5F4F0"))
                }
                .padding(10)
                .background(Color(hex: "#1E1E22"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

                // Yeni Müşteri Ekle
                Button {
                    withAnimation(.spring(response: 0.3)) { showNewClientInline.toggle() }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: "#A09FA6"))
                            .frame(width: 40, height: 40)
                            .background(Color(hex: "#1E1E22"))
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yeni Müşteri Ekle")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(hex: "#F5F4F0"))
                            Text("İsim ve telefon bilgilerini gir")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "#A09FA6"))
                        }
                        Spacer()
                        Image(systemName: showNewClientInline ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#3A3A3C"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if showNewClientInline {
                    newClientInlineForm
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                ThinDivider()

                if filteredClients.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 36)).foregroundStyle(Color(hex: "#2C2C2E"))
                        Text("Müşteri bulunamadı")
                            .font(.system(size: 14)).foregroundStyle(Color(hex: "#A09FA6"))
                    }
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredClients.enumerated()), id: \.element.id) { index, client in
                            Button {
                                withAnimation(.spring(response: 0.2)) {
                                    selectedClient = selectedClient?.id == client.id ? nil : client
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(client.initials)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#F5F4F0"))
                                        .frame(width: 40, height: 40)
                                        .background(Color(hex: "#1E1E22"))
                                        .clipShape(Circle())
                                        .overlay(Circle().strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(client.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(Color(hex: "#F5F4F0"))
                                        Text(client.packageName)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color(hex: "#A09FA6"))
                                    }

                                    Spacer()

                                    if selectedClient?.id == client.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color(hex: "#F5F4F0"))
                                    } else {
                                        Circle()
                                            .strokeBorder(Color(hex: "#2C2C2E"), lineWidth: 1.5)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if index < filteredClients.count - 1 {
                                Rectangle()
                                    .fill(Color(hex: "#1E1E22"))
                                    .frame(height: 0.5)
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }

                Spacer().frame(height: 100)
            }
        }
        .scrollBounceBehavior(.always)
    }

    // MARK: - Inline yeni müşteri formu
    private var newClientInlineForm: some View {
        VStack(spacing: 12) {
            TextField("Ad Soyad *", text: $newClientName)
                .font(.system(size: 15)).foregroundStyle(Color(hex: "#F5F4F0"))
                .tint(Color(hex: "#F5F4F0"))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(Color(hex: "#2C2C2E"))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                TextField("Telefon (opsiyonel)", text: $newClientPhone)
                    .font(.system(size: 15)).foregroundStyle(Color(hex: "#F5F4F0"))
                    .tint(Color(hex: "#F5F4F0"))
                    .keyboardType(.phonePad)
                    .padding(12)
                    .background(Color(hex: "#2C2C2E"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(
                        phoneFieldTouched && !isValidPhone(newClientPhone) ? Color(hex: "#E05C5C") : Color.clear,
                        lineWidth: 1.5
                    ))
                    .onChange(of: newClientPhone) { phoneFieldTouched = true }
                if phoneFieldTouched && !isValidPhone(newClientPhone) {
                    Text("Geçerli bir telefon numarası girin (05XX XXX XX XX)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#E05C5C"))
                        .padding(.horizontal, 4)
                }
            }

            Button {
                let trimmed = newClientName.trimmingCharacters(in: .whitespaces)
                guard trimmed.count >= 2 else { return }
                if let newClient = db.addClient(name: trimmed, phone: newClientPhone, totalSessions: 0) {
                    selectedClient = newClient
                    newClientName = ""
                    newClientPhone = ""
                    showNewClientInline = false
                    advanceToStep2(sessions: newClient.remainingSessions)
                }
            } label: {
                Text("Müşteriyi Ekle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#141416"))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(hex: "#F5F4F0"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .opacity(newClientName.trimmingCharacters(in: .whitespaces).count >= 2 ? 1.0 : 0.4)
            .disabled(newClientName.trimmingCharacters(in: .whitespaces).count < 2)
        }
        .padding(16)
        .background(Color(hex: "#1E1E22"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
    }

    // MARK: - Adım 2: Ne Zaman & Nasıl
    private var step2View: some View {
        VStack(spacing: 0) {
            if let client = selectedClient {
                HStack(spacing: 10) {
                    Text(client.initials)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#F5F4F0"))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#2C2C2E"))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text(client.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "#F5F4F0"))
                        Text(client.packageName)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#A09FA6"))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "#1E1E22"))

                ThinDivider()
            }

            ScrollView {
                VStack(spacing: 14) {
                    // ZAMANLAMA
                    FormSection(title: "ZAMANLAMA") {
                        VStack(spacing: 0) {
                            HStack(spacing: 3) {
                                modeTab(title: "Tek Seferlik", isSelected: appointmentMode == .single) {
                                    withAnimation(.spring(response: 0.3)) { appointmentMode = .single }
                                }
                                modeTab(title: "↻ Tekrarlayan", isSelected: appointmentMode == .recurring) {
                                    withAnimation(.spring(response: 0.3)) { appointmentMode = .recurring }
                                }
                            }
                            .padding(3)
                            .background(Color(hex: "#1E1E22"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
                            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 10)

                            ThinDivider()

                            if appointmentMode == .single {
                                singleDateBlock
                            } else {
                                recurringBlock
                            }
                        }
                    }

                    // ANTRENMAN
                    FormSection(title: "ANTRENMAN") {
                        VStack(spacing: 0) {
                            trainingTypeSection
                            ThinDivider().padding(.horizontal, 14)
                            durationSection
                        }
                    }

                    // NOT
                    FormSection(title: "NOT (OPSİYONEL)") {
                        ZStack(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("Antrenman notu, özel talimatlar...")
                                    .font(.system(size: 14)).foregroundStyle(Color(hex: "#4A4A55"))
                                    .padding(.horizontal, 18).padding(.vertical, 18)
                            }
                            TextEditor(text: $note)
                                .font(.system(size: 14)).foregroundStyle(Color(hex: "#F5F4F0"))
                                .scrollContentBackground(.hidden).background(Color.clear)
                                .frame(minHeight: 80).padding(.horizontal, 10).padding(.vertical, 10)
                        }
                    }

                    VStack(spacing: 6) {
                        Button { saveAndDismiss() } label: {
                            Text("Randevuyu Kaydet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(hex: "#141416"))
                                .frame(maxWidth: .infinity).frame(height: 52)
                                .background(Color(hex: "#F5F4F0"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .opacity(step2Valid ? 1.0 : 0.4)
                        .disabled(!step2Valid)

                        if let msg = step2ValidationMessage {
                            Text(msg)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "#E05C5C"))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
                }
                .padding(.top, 16)
                .onTapGesture {
                    expandedSlotId = nil
                }
            }
            .scrollBounceBehavior(.always)
        }
    }

    // MARK: - Antrenman türü
    private var trainingTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "flame.fill").font(.system(size: 14)).foregroundStyle(Color(hex: "#F5F4F0")).frame(width: 20)
                Text("Antrenman Türü").font(.system(size: 15)).foregroundStyle(Color(hex: "#A09FA6"))
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(trainingTypes, id: \.self) { type in
                        Button { selectedType = type } label: {
                            Text(type)
                                .font(.system(size: 13))
                                .foregroundStyle(selectedType == type ? Color(hex: "#F5F4F0") : Color(hex: "#A09FA6"))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(selectedType == type ? Color(hex: "#3A3A3C") : Color(hex: "#2C2C2E"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 12)
            }
        }
    }

    // MARK: - Süre
    private var durationSection: some View {
        HStack {
            Image(systemName: "timer").font(.system(size: 14)).foregroundStyle(Color(hex: "#F5F4F0")).frame(width: 20)
            Text("Süre").font(.system(size: 15)).foregroundStyle(Color(hex: "#A09FA6"))
            Spacer()
            HStack(spacing: 14) {
                Button {
                    if let idx = durationSteps.firstIndex(of: duration), idx > 0 { duration = durationSteps[idx - 1] }
                } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 22)).foregroundStyle(Color(hex: "#F5F4F0"))
                }
                .buttonStyle(.plain).disabled(duration == durationSteps.first)

                Text("\(duration) dk").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: "#F5F4F0")).frame(minWidth: 52, alignment: .center)

                Button {
                    if let idx = durationSteps.firstIndex(of: duration), idx < durationSteps.count - 1 { duration = durationSteps[idx + 1] }
                } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundStyle(Color(hex: "#F5F4F0"))
                }
                .buttonStyle(.plain).disabled(duration == durationSteps.last)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
    }

    // MARK: - Tek seferlik tarih/saat bloğu
    private var singleDateBlock: some View {
        VStack(spacing: 0) {
            // Seçim durumu
            HStack {
                Text("Takvimden tarih seç")
                    .font(.system(size: 13)).foregroundStyle(Color(hex: "#A09FA6"))
                Spacer()
                Text(selectedDate.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "tr_TR"))))
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: "#F5F4F0"))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            // Mini takvim
            MultiDateCalendarView(
                currentMonth: $singleCalendarMonth,
                selectedDates: Binding(
                    get: { [Calendar.current.startOfDay(for: selectedDate)] },
                    set: { _ in }
                ),
                maxSelections: 1,
                onDateTapped: { date in
                    withAnimation(.spring(response: 0.2)) {
                        selectedDate = date
                    }
                }
            )
            .padding(.horizontal, 10).padding(.bottom, 8)

            ThinDivider().padding(.horizontal, 14)

            TimePickerRow(hour: $selectedHour, minute: $selectedMinute, isExpanded: $showTimePicker)
        }
    }

    // MARK: - Tekrarlayan blok (takvim tabanlı)
    private var recurringBlock: some View {
        VStack(spacing: 0) {
            // Ders sayısı
            HStack {
                Image(systemName: "number").font(.system(size: 14)).foregroundStyle(Color(hex: "#F5F4F0")).frame(width: 20)
                Text("Ders Sayısı").font(.system(size: 15)).foregroundStyle(Color(hex: "#A09FA6"))
                Spacer()
                HStack(spacing: 14) {
                    Button {
                        if recurringSessionCount > 2 {
                            recurringSessionCount -= 1
                            trimSlotsIfNeeded()
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill").font(.system(size: 22)).foregroundStyle(Color(hex: "#F5F4F0"))
                    }
                    .buttonStyle(.plain).disabled(recurringSessionCount <= 2)

                    Text("\(recurringSessionCount)")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: "#F5F4F0"))
                        .frame(minWidth: 32, alignment: .center)

                    Button {
                        if recurringSessionCount < 20 { recurringSessionCount += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundStyle(Color(hex: "#F5F4F0"))
                    }
                    .buttonStyle(.plain).disabled(recurringSessionCount >= 20)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 14)

            ThinDivider().padding(.horizontal, 14)

            // Seçim durumu
            HStack {
                Text("Takvimden tarih seç")
                    .font(.system(size: 13)).foregroundStyle(Color(hex: "#A09FA6"))
                Spacer()
                Text("\(recurringSlots.count)/\(recurringSessionCount)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(recurringSlots.count == recurringSessionCount ? Color(hex: "#4CAF50") : Color(hex: "#E05C5C"))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            // Mini takvim
            MultiDateCalendarView(
                currentMonth: $recurringCalendarMonth,
                selectedDates: Binding(
                    get: { Set(recurringSlots.map { Calendar.current.startOfDay(for: $0.date) }) },
                    set: { _ in }
                ),
                maxSelections: recurringSessionCount,
                onDateTapped: { date in
                    toggleDate(date)
                }
            )
            .padding(.horizontal, 10).padding(.bottom, 8)

            // Seçilen tarihler listesi
            if !recurringSlots.isEmpty {
                ThinDivider().padding(.horizontal, 14)

                VStack(spacing: 0) {
                    ForEach(Array(sortedSlots.enumerated()), id: \.element.id) { index, slot in
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "#5C6BC0"))
                                .frame(width: 20)

                            Text(slot.date.formatted(.dateTime.day().month(.abbreviated).weekday(.abbreviated).locale(Locale(identifier: "tr_TR"))))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "#F5F4F0"))

                            Spacer()

                            Text(String(format: "%02d:%02d", slot.hour, slot.minute))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(expandedSlotId == slot.id ? Color(hex: "#141416") : Color(hex: "#F5F4F0"))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(expandedSlotId == slot.id ? Color(hex: "#F5F4F0") : Color(hex: "#2C2C2E"))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        if expandedSlotId == slot.id {
                                            expandedSlotId = nil
                                        } else {
                                            editingHour = slot.hour
                                            editingMinute = slot.minute
                                            expandedSlotId = slot.id
                                        }
                                    }
                                }

                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: "#4A4A55"))
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2)) {
                                        if expandedSlotId == slot.id { expandedSlotId = nil }
                                        recurringSlots.removeAll { $0.id == slot.id }
                                    }
                                }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)

                        if index < sortedSlots.count - 1 && expandedSlotId != slot.id {
                            ThinDivider().padding(.horizontal, 14)
                        }
                    }
                }

                // Saat seçici — TimePickerRow ile aynı yapı
                if expandedSlotId != nil {
                    ThinDivider().padding(.horizontal, 14)
                    TimePickerRow(hour: $editingHour, minute: $editingMinute, isExpanded: .constant(true))
                        .onChange(of: editingHour) { _, newH in
                            if let id = expandedSlotId, let idx = recurringSlots.firstIndex(where: { $0.id == id }) {
                                recurringSlots[idx].hour = newH
                            }
                        }
                        .onChange(of: editingMinute) { _, newM in
                            if let id = expandedSlotId, let idx = recurringSlots.firstIndex(where: { $0.id == id }) {
                                recurringSlots[idx].minute = newM
                            }
                        }
                }
            }
        }
    }

    private var sortedSlots: [RecurringSlot] {
        recurringSlots.sorted { $0.date < $1.date }
    }

    private func toggleDate(_ date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        if let idx = recurringSlots.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            _ = withAnimation(.spring(response: 0.2)) { recurringSlots.remove(at: idx) }
        } else if recurringSlots.count < recurringSessionCount {
            withAnimation(.spring(response: 0.2)) {
                recurringSlots.append(RecurringSlot(date: day))
            }
        }
    }

    private func trimSlotsIfNeeded() {
        if recurringSlots.count > recurringSessionCount {
            recurringSlots = Array(recurringSlots.sorted { $0.date < $1.date }.prefix(recurringSessionCount))
        }
    }

    // MARK: - Mode Tab helper
    private func modeTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color(hex: "#141416") : Color(hex: "#A09FA6"))
                .frame(maxWidth: .infinity).padding(.vertical, 7)
                .background(isSelected ? Color(hex: "#F5F4F0") : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Multi Date Calendar View
struct MultiDateCalendarView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDates: Set<Date>
    let maxSelections: Int
    let onDateTapped: (Date) -> Void

    private let calendar = Calendar.current
    private let dayLabels = ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth).capitalized
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }

        // Pazartesi=1 ... Pazar=7 (ISO)
        let weekday = calendar.component(.weekday, from: firstDay)
        let offset = (weekday - 2 + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    var body: some View {
        VStack(spacing: 8) {
            // Ay navigasyonu
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#A09FA6"))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Spacer()
                Text(monthTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#F5F4F0"))
                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#A09FA6"))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            // Gün başlıkları
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "#4A4A55"))
                        .frame(maxWidth: .infinity)
                }
            }

            // Gün grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, dateOpt in
                    if let date = dateOpt {
                        let day = calendar.startOfDay(for: date)
                        let isSelected = selectedDates.contains(day)
                        let isPast = day < calendar.startOfDay(for: Date())
                        let isToday = calendar.isDateInToday(date)
                        let isFull = selectedDates.count >= maxSelections && !isSelected

                        Button {
                            if !isPast { onDateTapped(date) }
                        } label: {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(
                                    isPast ? Color(hex: "#3A3A3C") :
                                    isSelected ? Color(hex: "#141416") :
                                    isToday ? Color(hex: "#5C6BC0") :
                                    isFull ? Color(hex: "#4A4A55") :
                                    Color(hex: "#F5F4F0")
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    isSelected ? Color(hex: "#F5F4F0") :
                                    isToday ? Color(hex: "#5C6BC0").opacity(0.15) :
                                    Color.clear
                                )
                                .clipShape(Circle())
                                .overlay {
                                    if isPast {
                                        GeometryReader { geo in
                                            Path { path in
                                                path.move(to: CGPoint(x: geo.size.width * 0.75, y: geo.size.height * 0.2))
                                                path.addLine(to: CGPoint(x: geo.size.width * 0.25, y: geo.size.height * 0.8))
                                            }
                                            .stroke(Color(hex: "#3A3A3C"), lineWidth: 1)
                                        }
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(isPast)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .padding(8)
    }
}

// MARK: - Time Picker Row
struct TimePickerRow: View {
    @Binding var hour: Int
    @Binding var minute: Int
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "clock").font(.system(size: 14)).foregroundStyle(Color(hex: "#F5F4F0")).frame(width: 20)
                Text("Saat").font(.system(size: 15)).foregroundStyle(Color(hex: "#A09FA6"))
                Spacer()
                Text(String(format: "%02d:%02d", hour, minute))
                    .font(.system(size: 15, weight: .medium)).foregroundStyle(Color(hex: "#F5F4F0"))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(hex: "#2C2C2E")).clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }

            if isExpanded {
                VStack(spacing: 6) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(6...22, id: \.self) { h in
                                Text(String(format: "%02d", h))
                                    .font(.system(size: 13, weight: hour == h ? .semibold : .regular))
                                    .foregroundStyle(hour == h ? Color(hex: "#F5F4F0") : Color(hex: "#4A4A55"))
                                    .frame(width: 38, height: 30)
                                    .background(hour == h ? Color(hex: "#2C2C2E") : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .onTapGesture { withAnimation(.spring(response: 0.2)) { hour = h } }
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                    HStack(spacing: 6) {
                        ForEach([0, 15, 30, 45], id: \.self) { m in
                            Text(String(format: ":%02d", m))
                                .font(.system(size: 13, weight: minute == m ? .semibold : .regular))
                                .foregroundStyle(minute == m ? Color(hex: "#F5F4F0") : Color(hex: "#4A4A55"))
                                .frame(maxWidth: .infinity).frame(height: 30)
                                .background(minute == m ? Color(hex: "#2C2C2E") : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .onTapGesture { withAnimation(.spring(response: 0.2)) { minute = m } }
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.vertical, 8)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Form Section
struct FormSection<Content: View>: View {
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
                .padding(.horizontal, 20)
        }
    }
}

#Preview {
    NewAppointmentView()
        .modelContainer(for: [Client.self, Appointment.self], inMemory: true)
}
