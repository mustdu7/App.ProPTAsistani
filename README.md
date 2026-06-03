# Pro PT Asistani

Kisisel antrenorluk isini kolayca yonet.

![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-red)

## Hakkinda

Pro PT Asistani, kisisel antrenorlerin musterilerini, randevularini ve seanslarini tek bir yerden yonetmelerini saglayan bir iOS uygulamasidir.

## Ozellikler

- **Randevu Yonetimi** — Tek seferlik veya tekrarlayan randevular olustur, takvim uzerinden tarih ve saat sec
- **Musteri Takibi** — Musteri bilgileri, seans durumu ve ilerleme cubugu
- **Gunluk Dashboard** — Bugunun ve yarinin randevularini tek bakista gor
- **Takvim Gorunumu** — Aylik takvimde randevulari tur bazli renklerle gor
- **Bildirimler** — Randevulardan 1 saat once hatirlatma bildirimi
- **iOS Widget** — Bugunun randevularini ana ekranda gor
- **Swipe Aksiyonlar** — Sola kaydirarak randevu sil

## Teknolojiler

| Teknoloji | Kullanim |
|-----------|----------|
| SwiftUI | Tum kullanici arayuzu |
| SwiftData | Yerel veri saklama |
| WidgetKit | Ana ekran widget'i |
| UserNotifications | Randevu hatirlatmalari |
| Google AdMob | Reklam entegrasyonu |
| App Tracking Transparency | Reklam izin yonetimi |

## Gereksinimler

- iOS 17.0+
- Xcode 16.0+
- Swift 5.9+

## Kurulum

```bash
# Repoyu klonla
git clone https://github.com/mustdu7/App.ProPTAsistani.git

# Proje dosyasini olustur (XcodeGen gerekli)
cd App.ProPTAsistani
xcodegen generate

# Xcode ile ac
open ProPTAsistani.xcodeproj
```

Xcode acildiktan sonra **File > Packages > Resolve Package Versions** ile SPM paketlerini indir.

## Proje Yapisi

```
ProPTAsistani/
├── Models/          # Client, Appointment, AppSettings, MockDataStore
├── Managers/        # DatabaseManager, NotificationManager
├── Views/           # SwiftUI ekranlari
│   ├── TodayView        # Gunluk dashboard
│   ├── CalendarView     # Aylik takvim
│   ├── ClientsView      # Musteri listesi
│   ├── ClientDetailView # Musteri detay
│   ├── NewAppointmentView # Randevu olusturma
│   ├── EditAppointmentView # Randevu duzenleme
│   ├── SettingsView     # Ayarlar
│   ├── WelcomeView      # Onboarding
│   └── BannerAdView     # AdMob banner
├── Extensions.swift # Color(hex:), typeColor, SwipeableRow
├── ContentView.swift # Tab navigation
└── ProPTAsistaniApp.swift # App entry point

ProPTWidget/         # iOS Widget extension
docs/                # GitHub Pages (yasal metinler)
```

## Yasal

- [Gizlilik Politikasi](https://mustdu7.github.io/App.ProPTAsistani/gizlilik-politikasi.html)
- [Kullanim Kosullari](https://mustdu7.github.io/App.ProPTAsistani/kullanim-kosullari.html)
- [KVKK Aydinlatma Metni](https://mustdu7.github.io/App.ProPTAsistani/kvkk.html)
- [Cerez Politikasi](https://mustdu7.github.io/App.ProPTAsistani/cerez-politikasi.html)

## Destek

Sorulariniz veya geri bildirimleriniz icin: [mustdu7@gmail.com](mailto:mustdu7@gmail.com)
