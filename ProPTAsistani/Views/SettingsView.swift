import SwiftUI
import StoreKit

private struct LegalLink: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let url: String
}

private let legalLinks: [LegalLink] = [
    LegalLink(icon: "lock.shield",            title: "Gizlilik Politikası",    url: "https://mustdu7.github.io/App.ProPTAsistani/gizlilik-politikasi.html"),
    LegalLink(icon: "doc.text",               title: "Kullanım Koşulları",     url: "https://mustdu7.github.io/App.ProPTAsistani/kullanim-kosullari.html"),
    LegalLink(icon: "person.text.rectangle",  title: "KVKK Aydınlatma Metni", url: "https://mustdu7.github.io/App.ProPTAsistani/kvkk.html"),
    LegalLink(icon: "cookie",                 title: "Çerez Politikası",       url: "https://mustdu7.github.io/App.ProPTAsistani/cerez-politikasi.html"),
]

struct SettingsView: View {

    @Bindable private var settings = AppSettings.shared
    @State private var db = DatabaseManager.shared
    @Environment(\.requestReview) var requestReview
    @Environment(\.openURL)       var openURL

    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        ZStack {
            Color(hex: "#141416").ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Profil")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color(hex: "#F5F4F0"))
                        Text("Pro PT Asistanı v1.0")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#A09FA6"))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Rectangle().fill(Color(hex: "#2A2A2D")).frame(height: 0.5)

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: Profil Kartı
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Text(settings.ptInitials)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#F5F4F0"))
                                    .frame(width: 48, height: 48)
                                    .background(Color(hex: "#2C2C2E"))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    TextField("Adınız", text: $settings.ptName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#F5F4F0"))
                                        .tint(Color(hex: "#F5F4F0"))
                                    Text("Personal Trainer")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "#A09FA6"))
                                }

                                Spacer()

                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color(hex: "#3A3A3C"))
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "#1E1E22"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))

                        // MARK: Bildirimler
                        SettingsSection(title: "BİLDİRİMLER") {
                            SettingsRow(icon: "bell.fill") {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Randevu Hatırlatıcı")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#F5F4F0"))
                                    Text("Randevu öncesi bildirim al")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "#A09FA6"))
                                }
                            } trailing: {
                                HStack(spacing: 8) {
                                    Image(systemName: NotificationManager.shared.isAuthorized
                                          ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(NotificationManager.shared.isAuthorized
                                                         ? Color(hex: "#4CAF50") : Color(hex: "#E05C5C"))
                                    Toggle("", isOn: $settings.notificationsEnabled)
                                        .labelsHidden()
                                        .tint(Color(hex: "#F5F4F0"))
                                }
                            }

                            if settings.notificationsEnabled && !NotificationManager.shared.isAuthorized {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "#F0A500"))
                                    Text("Bildirim izni gerekli")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "#F0A500"))
                                    Spacer()
                                    Button {
                                        UIApplication.shared.open(
                                            URL(string: UIApplication.openSettingsURLString)!)
                                    } label: {
                                        Text("Ayarları Aç")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#F5F4F0"))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(10)
                                .background(Color(hex: "#2A1F0A"))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.horizontal, 14)
                                .padding(.bottom, 4)
                            }

                            Divider().background(Color(hex: "#2A2A2D")).padding(.horizontal, 14)

                            SettingsRow(icon: "clock.fill") {
                                Text("1 Saat Önce")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#F5F4F0"))
                            } trailing: {
                                Toggle("", isOn: $settings.notify1h)
                                    .labelsHidden()
                                    .tint(Color(hex: "#F5F4F0"))
                                    .disabled(!settings.notificationsEnabled)
                            }
                            .opacity(settings.notificationsEnabled ? 1 : 0.4)
                        }

                        // MARK: Veri
                        SettingsSection(title: "VERİ") {
                            Button { showDeleteConfirm = true } label: {
                                SettingsRow(icon: "trash", iconColor: Color(hex: "#E05C5C")) {
                                    Text("Tüm Verileri Sil")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#E05C5C"))
                                } trailing: { EmptyView() }
                            }
                            .buttonStyle(.plain)
                            .confirmationDialog("Tüm veriler silinecek", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                                Button("Sil", role: .destructive) {
                                    db.deleteAllData()
                                }
                                Button("İptal", role: .cancel) { }
                            } message: {
                                Text("Bu işlem geri alınamaz.")
                            }
                        }

                        // MARK: Uygulama
                        SettingsSection(title: "UYGULAMA") {
                            Button { requestReview() } label: {
                                SettingsRow(icon: "star") {
                                    Text("Uygulamayı Değerlendir")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#F5F4F0"))
                                } trailing: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(hex: "#3A3A3C"))
                                }
                            }
                            .buttonStyle(.plain)

                            Divider().background(Color(hex: "#2A2A2D")).padding(.horizontal, 14)

                            Button {
                                if let url = URL(string: "mailto:mustdu7@gmail.com?subject=Pro%20PT%20Asistan%C4%B1%20Geri%20Bildirim") {
                                    openURL(url)
                                }
                            } label: {
                                SettingsRow(icon: "envelope") {
                                    Text("Geri Bildirim Gönder")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#F5F4F0"))
                                } trailing: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(hex: "#3A3A3C"))
                                }
                            }
                            .buttonStyle(.plain)

                            Divider().background(Color(hex: "#2A2A2D")).padding(.horizontal, 14)

                            SettingsRow(icon: "info.circle") {
                                Text("Sürüm 1.0.0")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#F5F4F0"))
                            } trailing: {
                                Text("Build 1")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "#A09FA6"))
                            }
                        }

                        // MARK: Yasal
                        VStack(spacing: 0) {
                            ForEach(legalLinks) { item in
                                if let url = URL(string: item.url) {
                                    Link(destination: url) {
                                        SettingsRow(icon: item.icon) {
                                            Text(item.title)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(Color(hex: "#F5F4F0"))
                                        } trailing: {
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color(hex: "#3A3A3C"))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    if item.title != "Çerez Politikası" {
                                        ThinDivider().padding(.horizontal, 14)
                                    }
                                }
                            }
                        }
                        .background(Color(hex: "#1E1E22"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .scrollBounceBehavior(.always)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Task { await NotificationManager.shared.checkAuthorizationStatus() }
        }
        .onChange(of: settings.notify1h) { _, newValue in
            let upcoming = db.appointments.filter { $0.date > Date() }
            for appt in upcoming {
                NotificationManager.shared.cancelNotification(id: appt.id.uuidString)
                if newValue {
                    NotificationManager.shared.scheduleNotification(
                        id: appt.id.uuidString,
                        clientName: appt.clientName,
                        date: appt.date,
                        type: appt.type,
                        notify1h: newValue
                    )
                }
            }
        }
    }
}

// MARK: - Section
private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "#A09FA6"))
                .padding(.bottom, 8)

            VStack(spacing: 0) { content }
                .background(Color(hex: "#1E1E22"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
        }
    }
}

// MARK: - Row
private struct SettingsRow<Label: View, Trailing: View>: View {
    let icon: String
    var iconColor: Color = Color(hex: "#F5F4F0")
    @ViewBuilder let label: Label
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(Color(hex: "#2C2C2E"))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            label
            Spacer()
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Client.self, Appointment.self], inMemory: true)
}
