import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import UIKit

/// Owns App Tracking Transparency, Mobile Ads SDK startup, and the
/// preload/show lifecycle for the free-tier interstitial. The banner
/// (see BannerAdView.swift) loads itself independently.
final class AdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AdManager()
    static let interstitialAdUnitID = "ca-app-pub-9638598348702189/3710818679"

    private var interstitial: InterstitialAd?

    private override init() {
        super.init()
    }

    /// Call once at app launch.
    func start() {
        ATTrackingManager.requestTrackingAuthorization { _ in
            DispatchQueue.main.async {
                MobileAds.shared.start(completionHandler: nil)
                self.loadInterstitial()
            }
        }
    }

    func loadInterstitial() {
        InterstitialAd.load(with: Self.interstitialAdUnitID, request: Request()) { [weak self] ad, error in
            guard let self, error == nil else { return }
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
        }
    }

    func showInterstitial(from rootViewController: UIViewController?) {
        guard let interstitial, let rootViewController else { return }
        interstitial.present(from: rootViewController)
    }

    /// iOS 15+ safe way to resolve the key window's root view controller
    /// (avoids the deprecated `UIApplication.shared.keyWindow`). Shared by
    /// both the banner and the interstitial-presenting call sites.
    static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }

    // MARK: - FullScreenContentDelegate

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        loadInterstitial()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        loadInterstitial()
    }
}
