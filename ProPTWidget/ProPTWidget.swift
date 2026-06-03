//
//  ProPTWidget.swift
//  ProPTWidget
//

import WidgetKit
import SwiftUI

// MARK: - Shared Data Model

struct WidgetAppointmentItem: Codable {
    var clientName: String
    var clientInitials: String
    var time: String
    var type: String
}

// MARK: - Timeline Entry

struct ProPTEntry: TimelineEntry {
    let date: Date
    let appointments: [WidgetAppointmentItem]
    let ptInitials: String
}

// MARK: - Provider

struct ProPTProvider: TimelineProvider {
    private let appGroup = "group.com.must.proptasistani"

    func placeholder(in context: Context) -> ProPTEntry {
        ProPTEntry(date: .now, appointments: [
            WidgetAppointmentItem(clientName: "Ahmet Yılmaz", clientInitials: "AY", time: "09:00", type: "Kuvvet"),
            WidgetAppointmentItem(clientName: "Zeynep Kaya",  clientInitials: "ZK", time: "10:30", type: "Kardio"),
            WidgetAppointmentItem(clientName: "Mert Demir",   clientInitials: "MD", time: "12:00", type: "Esneklik"),
        ], ptInitials: "PT")
    }

    func getSnapshot(in context: Context, completion: @escaping (ProPTEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProPTEntry>) -> Void) {
        let entry = loadEntry()
        let next  = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> ProPTEntry {
        let ud         = UserDefaults(suiteName: appGroup)
        let initials   = ud?.string(forKey: "widget_ptInitials") ?? "PT"
        var appts: [WidgetAppointmentItem] = []
        if let data    = ud?.data(forKey: "widget_todayAppointments"),
           let decoded = try? JSONDecoder().decode([WidgetAppointmentItem].self, from: data) {
            appts = decoded
        }
        return ProPTEntry(date: .now, appointments: appts, ptInitials: initials)
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: ProPTEntry

    var body: some View {
        ZStack {
            Color(widgetHex: "#141416")

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 7) {
                    avatarBadge(entry.ptInitials, size: 24, fontSize: 9)
                    Text("Bugün")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(widgetHex: "#F5F4F0"))
                    Spacer()
                    Text("\(entry.appointments.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(widgetHex: "#A09FA6"))
                }
                .padding(.bottom, 8)

                Color(widgetHex: "#2A2A2D").frame(height: 0.5).padding(.bottom, 8)

                if entry.appointments.isEmpty {
                    Spacer()
                    Text("Randevu\nyok")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(widgetHex: "#4A4A55"))
                        .multilineTextAlignment(.leading)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(entry.appointments.prefix(3).enumerated()), id: \.offset) { _, appt in
                            HStack(spacing: 6) {
                                Text(appt.time)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color(widgetHex: "#A09FA6"))
                                    .frame(width: 34, alignment: .leading)
                                Text(appt.clientName.components(separatedBy: " ").first ?? appt.clientName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(widgetHex: "#F5F4F0"))
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                        if entry.appointments.count > 3 {
                            Text("+\(entry.appointments.count - 3) daha")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(widgetHex: "#4A4A55"))
                        }
                    }
                    Spacer()
                }
            }
            .padding(13)
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: ProPTEntry

    var body: some View {
        ZStack {
            Color(widgetHex: "#141416")

            HStack(spacing: 0) {

                // Left panel
                VStack(alignment: .leading, spacing: 0) {
                    avatarBadge(entry.ptInitials, size: 30, fontSize: 11)

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayNum)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(Color(widgetHex: "#F5F4F0"))
                        Text(monthName)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(widgetHex: "#A09FA6"))
                    }

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(entry.appointments.count)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(widgetHex: "#F5F4F0"))
                        Text("randevu")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(widgetHex: "#A09FA6"))
                    }
                }
                .padding(14)
                .frame(width: 108)

                Color(widgetHex: "#2A2A2D").frame(width: 0.5).padding(.vertical, 12)

                // Right panel
                VStack(alignment: .leading, spacing: 0) {
                    if entry.appointments.isEmpty {
                        Spacer()
                        Text("Bugün randevu yok")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(widgetHex: "#4A4A55"))
                            .padding(.horizontal, 14)
                        Spacer()
                    } else {
                        ForEach(Array(entry.appointments.prefix(4).enumerated()), id: \.offset) { idx, appt in
                            VStack(spacing: 0) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(typeColor(appt.type))
                                        .frame(width: 6, height: 6)

                                    Text(appt.time)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundStyle(Color(widgetHex: "#A09FA6"))
                                        .frame(width: 34, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(appt.clientName)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(Color(widgetHex: "#F5F4F0"))
                                            .lineLimit(1)
                                        Text(appt.type)
                                            .font(.system(size: 10))
                                            .foregroundStyle(typeColor(appt.type).opacity(0.75))
                                    }

                                    Spacer()

                                    avatarBadge(appt.clientInitials, size: 24, fontSize: 8)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)

                                if idx < min(entry.appointments.count, 4) - 1 {
                                    Color(widgetHex: "#2A2A2D").frame(height: 0.5).padding(.horizontal, 12)
                                }
                            }
                        }

                        if entry.appointments.count > 4 {
                            Text("+\(entry.appointments.count - 4) randevu daha")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(widgetHex: "#4A4A55"))
                                .padding(.horizontal, 12)
                                .padding(.top, 4)
                        }

                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayNum: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: entry.date)
    }

    private var monthName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "MMMM"
        return f.string(from: entry.date).capitalized
    }
}

// MARK: - Entry View

struct ProPTWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ProPTEntry

    var body: some View {
        switch family {
        case .systemSmall: SmallWidgetView(entry: entry)
        default:           MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

struct ProPTWidget: Widget {
    let kind: String = "ProPTWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProPTProvider()) { entry in
            ProPTWidgetEntryView(entry: entry)
                .containerBackground(Color(widgetHex: "#141416"), for: .widget)
        }
        .configurationDisplayName("ProPT Randevular")
        .description("Bugünkü randevularınızı görüntüleyin.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ProPTWidget()
} timeline: {
    ProPTEntry(date: .now, appointments: [
        WidgetAppointmentItem(clientName: "Ahmet Yılmaz", clientInitials: "AY", time: "09:00", type: "Kuvvet"),
        WidgetAppointmentItem(clientName: "Zeynep Kaya",  clientInitials: "ZK", time: "10:30", type: "Kardio"),
    ], ptInitials: "PT")
}

#Preview(as: .systemMedium) {
    ProPTWidget()
} timeline: {
    ProPTEntry(date: .now, appointments: [
        WidgetAppointmentItem(clientName: "Ahmet Yılmaz", clientInitials: "AY", time: "09:00", type: "Kuvvet"),
        WidgetAppointmentItem(clientName: "Zeynep Kaya",  clientInitials: "ZK", time: "10:30", type: "Kardio"),
        WidgetAppointmentItem(clientName: "Mert Demir",   clientInitials: "MD", time: "12:00", type: "Esneklik"),
    ], ptInitials: "PT")
}

// MARK: - Helpers

private func avatarBadge(_ text: String, size: CGFloat, fontSize: CGFloat) -> some View {
    ZStack {
        Circle()
            .fill(Color(widgetHex: "#1E1E22"))
            .frame(width: size, height: size)
        Circle()
            .strokeBorder(Color(widgetHex: "#3A3A3C"), lineWidth: 1)
            .frame(width: size, height: size)
        Text(text)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(Color(widgetHex: "#F5F4F0"))
    }
}

private func typeColor(_ type: String) -> Color {
    switch type {
    case "Kuvvet":   return Color(widgetHex: "#5C6BC0")
    case "Kardio":   return Color(widgetHex: "#E05C5C")
    case "Esneklik": return Color(widgetHex: "#4CAF50")
    case "Beslenme": return Color(widgetHex: "#F0A500")
    default:         return Color(widgetHex: "#4A4A55")
    }
}

// MARK: - Color+Hex (widget-local, ayrı init adı ile çakışma önlenir)
extension Color {
    init(widgetHex hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
