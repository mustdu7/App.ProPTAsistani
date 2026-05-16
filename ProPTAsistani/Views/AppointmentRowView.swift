import SwiftUI

struct AppointmentRowView<A: AppointmentDisplaying>: View {
    let appointment: A
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Sol — saat kolonu
            VStack(spacing: 0) {
                Text(appointment.timeString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(appointment.isPast ? Color(hex: "#4A4A55") : Color(hex: "#F5F4F0"))
                    .frame(width: 44)

                if !isLast {
                    Rectangle()
                        .fill(appointment.isPast ? Color(hex: "#2A2A2D") : Color(hex: "#3A3A3C"))
                        .frame(width: 1, height: 16)
                        .padding(.top, 6)
                }
            }
            .padding(.top, 2)

            // Orta — kart
            HStack(spacing: 0) {
                // Sol accent bar
                Rectangle()
                    .fill(appointment.isPast ? Color(hex: "#3A3A3C") : typeColor(for: appointment.type))
                    .frame(width: 2.5)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 12,
                            bottomLeadingRadius: 12,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                    )

                VStack(spacing: 4) {
                    HStack {
                        Text(appointment.clientName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(appointment.isPast ? Color(hex: "#6A6A70") : Color(hex: "#F5F4F0"))

                        Spacer()

                        Text(appointment.type)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(
                                appointment.isPast
                                    ? Color(hex: "#4A4A55")
                                    : typeColor(for: appointment.type)
                            )
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                appointment.isPast
                                    ? Color(hex: "#2A2A2D")
                                    : typeColor(for: appointment.type).opacity(0.15)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: "#A09FA6"))
                            Text(appointment.durationString)
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "#A09FA6"))
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(appointment.isPast ? Color(hex: "#191919") : Color(hex: "#1E1E22"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        appointment.isPast ? Color(hex: "#222224") : Color(hex: "#2C2C2E"),
                        lineWidth: 0.5
                    )
            )
            .padding(.leading, 8)
        }
    }
}
