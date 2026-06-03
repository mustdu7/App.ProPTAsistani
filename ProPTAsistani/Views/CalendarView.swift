import SwiftUI

struct CalendarView: View {
    @State private var db = DatabaseManager.shared
    @State private var settings = AppSettings.shared

    @State private var selectedDate: Date = Date()
    @State private var selectedMonth: Date = Date()
    @State private var selectedEditAppointment: Appointment? = nil

    private var dayLabels: [String] { settings.dayLabels }
    private let cal = Calendar.current

    // MARK: - Month helpers
    private func monthDates(for date: Date) -> [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: date),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: date))
        else { return [] }
        let firstWeekday = settings.firstWeekdayOffset(for: firstDay)
        var dates: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            dates.append(cal.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        while dates.count % 7 != 0 { dates.append(nil) }
        return dates
    }

    private func appointments(for date: Date) -> [Appointment] {
        db.appointments
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Header month text
    private var headerMonthText: String {
        let raw = selectedMonth.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "tr_TR")))
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color(hex: "#141416").ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                ThinDivider()
                monthlyContent
            }
        }
        .sheet(item: $selectedEditAppointment) { apt in
            EditAppointmentView(appointment: apt)
                .presentationDetents([.large])
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
            db.fetchAppointments()
        }
        .refreshable {
            db.fetchClients()
            db.fetchAppointments()
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Takvim")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(hex: "#F5F4F0"))
                Text(headerMonthText)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#A09FA6"))
            }
            Spacer()

            HStack(spacing: 8) {
                chevronButton(icon: "chevron.left") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMonth = cal.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    }
                }
                chevronButton(icon: "chevron.right") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMonth = cal.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private func chevronButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "#F5F4F0"))
                .frame(width: 38, height: 38)
                .background(Color(hex: "#2C2C2E"))
                .clipShape(Circle())
        }
    }

    // MARK: - Monthly content
    private var monthlyContent: some View {
        let dates    = monthDates(for: selectedMonth)
        let columns  = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        let selAppts = appointments(for: selectedDate)
        let selInMonth = cal.isDate(selectedDate, equalTo: selectedMonth, toGranularity: .month)

        return ScrollView {
            VStack(spacing: 0) {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(dayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#A09FA6"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)

                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(Array(dates.enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            monthCell(date: date)
                        } else {
                            Color.clear.frame(maxWidth: .infinity).frame(height: 52)
                        }
                    }
                }
                .padding(.horizontal, 8)

                if selInMonth {
                    VStack(spacing: 0) {
                        HStack {
                            Text(formattedSelectedDay)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "#A09FA6"))
                            Spacer()
                            if !selAppts.isEmpty {
                                Text("\(selAppts.count) randevu")
                                    .font(.system(size: 12)).foregroundStyle(Color(hex: "#A09FA6"))
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 8)

                        if selAppts.isEmpty {
                            HStack {
                                Text("Bu gün randevu yok")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: "#A09FA6"))
                                Spacer()
                            }
                            .padding(.horizontal, 16).padding(.bottom, 8)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(Array(selAppts.enumerated()), id: \.element.id) { index, appt in
                                    AppointmentRowView(
                                        appointment: appt,
                                        isLast: index == selAppts.count - 1
                                    )
                                    .padding(.horizontal, 16)
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            selectedEditAppointment = appt
                                        } label: {
                                            Label("Düzenle", systemImage: "pencil")
                                        }
                                        .tint(Color(hex: "#5C6BC0"))
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            NotificationManager.shared.cancelNotification(id: appt.id.uuidString)
                                            db.deleteAppointment(appt)
                                        } label: {
                                            Label("Sil", systemImage: "trash")
                                        }
                                        .tint(Color(hex: "#E05C5C"))
                                    }
                                }
                            }
                        }
                    }
                }

                Color.clear.frame(height: 100)
            }
        }
        .scrollBounceBehavior(.always)
    }

    private var formattedSelectedDay: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "tr_TR")
        fmt.dateFormat = "d MMMM EEEE"
        return fmt.string(from: selectedDate)
    }

    // MARK: - Month cell
    private func monthCell(date: Date) -> some View {
        let isToday    = cal.isDateInToday(date)
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
        let dayNum     = cal.component(.day, from: date)
        let appts      = appointments(for: date)

        return Button {
            withAnimation(.spring(response: 0.25)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isToday {
                        Circle().fill(Color(hex: "#F5F4F0")).frame(width: 26, height: 26)
                    } else if isSelected {
                        Circle().fill(Color(hex: "#2C2C2E")).frame(width: 26, height: 26)
                    }
                    Text("\(dayNum)")
                        .font(.system(size: 13, weight: isToday ? .semibold : .regular))
                        .foregroundStyle(
                            isToday    ? Color(hex: "#141416") :
                            isSelected ? Color(hex: "#F5F4F0") :
                                         Color(hex: "#A09FA6")
                        )
                }
                HStack(spacing: 2) {
                    ForEach(Array(appts.prefix(3).enumerated()), id: \.offset) { _, appt in
                        Circle()
                            .fill(typeColor(for: appt.type))
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .overlay(Rectangle().strokeBorder(Color(hex: "#1E1E22"), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Client.self, Appointment.self], inMemory: true)
}
