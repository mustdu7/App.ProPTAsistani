import SwiftUI

struct WelcomeView: View {
    @Bindable private var settings = AppSettings.shared
    @State private var ptNameInput: String = ""
    @State private var currentPage: Int = 0
    @State private var appeared = false

    private var isNameValid: Bool {
        ptNameInput.trimmingCharacters(in: .whitespaces).count >= 2
    }

    private let features: [(icon: String, title: String, desc: String)] = [
        ("calendar.badge.clock", "Randevu Yönetimi", "Tek seferlik veya tekrarlayan randevuları kolayca oluştur ve takip et."),
        ("person.2.fill",        "Müşteri Takibi",   "Müşteri bilgileri, paket durumları ve seans geçmişi tek yerde."),
        ("bell.badge.fill",      "Hatırlatıcılar",   "Randevularından 1 saat önce bildirim al, hiçbir seansı kaçırma."),
    ]

    var body: some View {
        ZStack {
            Color(hex: "#141416").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Logo
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#F5F4F0").opacity(0.06))
                            .frame(width: 100, height: 100)
                        Circle()
                            .fill(Color(hex: "#F5F4F0").opacity(0.10))
                            .frame(width: 72, height: 72)
                        Text("PT")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color(hex: "#F5F4F0"))
                    }
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                    Text("Pro PT Asistanı")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color(hex: "#F5F4F0"))
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Text("Kişisel antrenörlük işini\nkolayca yönet")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#A09FA6"))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                }

                Spacer().frame(height: 48)

                // MARK: Özellikler
                VStack(spacing: 16) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: "#F5F4F0"))
                                .frame(width: 44, height: 44)
                                .background(Color(hex: "#1E1E22"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(feature.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#F5F4F0"))
                                Text(feature.desc)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "#A09FA6"))
                                    .lineLimit(2)
                            }

                            Spacer()
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8).delay(0.3 + Double(index) * 0.1),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                // MARK: İsim girişi ve başla
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Adın nedir?")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#A09FA6"))

                        TextField("Adınızı girin", text: $ptNameInput)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(hex: "#F5F4F0"))
                            .tint(Color(hex: "#F5F4F0"))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#1E1E22"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5)
                            )
                    }

                    Button {
                        let trimmed = ptNameInput.trimmingCharacters(in: .whitespaces)
                        settings.ptName = trimmed
                        withAnimation(.easeInOut(duration: 0.3)) {
                            settings.hasSeenWelcome = true
                        }
                    } label: {
                        Text("Başlayalım")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isNameValid ? Color(hex: "#141416") : Color(hex: "#141416").opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isNameValid ? Color(hex: "#F5F4F0") : Color(hex: "#F5F4F0").opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isNameValid)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: appeared)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

#Preview {
    WelcomeView()
}
