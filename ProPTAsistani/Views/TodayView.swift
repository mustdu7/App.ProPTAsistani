import SwiftUI

struct TodayView: View {
    @State private var db = DatabaseManager.shared
    @State private var selectedEditAppointment: Appointment? = nil
    var onNavigateToSettings: (() -> Void)? = nil

    private var todayAppointments: [Appointment] {
        let cal = Calendar.current
        return db.appointments.filter { cal.isDateInToday($0.date) }.sorted { $0.date < $1.date }
    }

    private var tomorrowAppointments: [Appointment] {
        let cal = Calendar.current
        return db.appointments.filter { cal.isDateInTomorrow($0.date) }.sorted { $0.date < $1.date }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM EEEE"
        return formatter.string(from: Date())
    }

    private var firstUpcomingIndex: Int? {
        todayAppointments.firstIndex(where: { !$0.isPast })
    }

    private var completedCount: Int {
        todayAppointments.filter { $0.isPast }.count
    }

    private var totalDurationText: String {
        let totalMinutes = todayAppointments.reduce(0) { $0 + $1.durationMinutes }
        if totalMinutes == 0 { return "0 dk" }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes) dk" }
        if minutes == 0 { return "\(hours) sa" }
        return "\(hours)s \(minutes)dk"
    }

    private var userInitials: String {
        AppSettings.shared.ptInitials
    }

    var body: some View {
        ZStack {
            Color(hex: "#141416").ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bugün")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color(hex: "#F5F4F0"))
                        Text(formattedDate)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#A09FA6"))
                    }

                    Spacer()

                    Button { onNavigateToSettings?() } label: {
                        Text(userInitials)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "#F5F4F0"))
                            .frame(width: 38, height: 38)
                            .background(Color(hex: "#2C2C2E"))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Rectangle()
                    .fill(Color(hex: "#2A2A2D"))
                    .frame(height: 0.5)

                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: Stat Cards
                        HStack(spacing: 8) {
                            StatCardView(icon: "calendar.fill",         value: "\(todayAppointments.count)", label: "Randevu")
                            StatCardView(icon: "clock.fill",            value: totalDurationText,            label: "Toplam Süre")
                            StatCardView(icon: "checkmark.circle.fill", value: "\(completedCount)",         label: "Tamamlandı")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                        // MARK: Bugün
                        HStack {
                            Text("Bugünkü Randevular")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "#A09FA6"))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        if todayAppointments.isEmpty {
                            HStack {
                                Text("Bugün randevu yok")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: "#3A3A3C"))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(Array(todayAppointments.enumerated()), id: \.element.id) { index, appt in
                                    if index == firstUpcomingIndex {
                                        NowIndicatorView()
                                            .padding(.horizontal, 20)
                                            .padding(.bottom, 2)
                                    }
                                    SwipeableRow(
                                        content: {
                                            AppointmentRowView(
                                                appointment: appt,
                                                isLast: index == todayAppointments.count - 1
                                            )
                                        },
                                        trailingActions: [
                                            SwipeAction(
                                                icon: "trash",
                                                label: "Sil",
                                                color: Color(hex: "#E05C5C"),
                                                handler: {
                                                    NotificationManager.shared.cancelNotification(id: appt.id.uuidString)
                                                    db.deleteAppointment(appt)
                                                }
                                            )
                                        ]
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                        }

                        // MARK: Yarın
                        if !tomorrowAppointments.isEmpty {
                            HStack {
                                Text("Yarınki Randevular")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#A09FA6"))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 8)

                            VStack(spacing: 6) {
                                ForEach(Array(tomorrowAppointments.enumerated()), id: \.element.id) { index, appt in
                                    SwipeableRow(
                                        content: {
                                            AppointmentRowView(
                                                appointment: appt,
                                                isLast: index == tomorrowAppointments.count - 1
                                            )
                                        },
                                        trailingActions: [
                                            SwipeAction(
                                                icon: "trash",
                                                label: "Sil",
                                                color: Color(hex: "#E05C5C"),
                                                handler: {
                                                    NotificationManager.shared.cancelNotification(id: appt.id.uuidString)
                                                    db.deleteAppointment(appt)
                                                }
                                            )
                                        ]
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
                .scrollBounceBehavior(.always)
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
            db.fetchAppointments()
        }
    }
}

// MARK: - Stat Card
private struct StatCardView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#5C6BC0"))
                Text(value)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "#F5F4F0"))
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#A09FA6"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#1E1E22"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
    }
}

// MARK: - Now Indicator
private struct NowIndicatorView: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(Color(hex: "#E05C5C")).frame(width: 6, height: 6)
            Text("Şimdi").font(.system(size: 11, weight: .medium)).foregroundStyle(Color(hex: "#E05C5C"))
            Rectangle().fill(Color(hex: "#E05C5C").opacity(0.3)).frame(height: 1)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Client.self, Appointment.self], inMemory: true)
}
