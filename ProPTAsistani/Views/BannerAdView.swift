import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 22/255, alpha: 1)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            banner.rootViewController = root
        }
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

struct AdBannerContainer: View {
    var body: some View {
        BannerAdView(adUnitID: "ca-app-pub-6127326528208744/4672841398")
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#141416"))
    }
}
