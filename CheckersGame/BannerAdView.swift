import SwiftUI
import GoogleMobileAds
import UIKit

/// Adaptive anchored banner for the free tier. Root view controller is
/// resolved via `AdManager.rootViewController()` (iOS 15+ safe, avoids the
/// deprecated `keyWindow`).
struct BannerAdView: UIViewRepresentable {
    let adUnitID = "ca-app-pub-9638598348702189/6336982017"

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = AdManager.rootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
