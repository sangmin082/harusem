import Foundation
import Observation
import AppTrackingTransparency
import GoogleMobileAds
import UIKit

/// AdMob 광고: 전면(5문제 완료 후 1회) + 리워드(힌트 충전).
/// 디버그 빌드는 Google 공개 테스트 유닛 ID를 사용한다 — 실제 ID로 개발 중 노출하면 계정 정지 위험.
@Observable
@MainActor
final class AdsService: NSObject {
    /// ⚠️ 임시: 신규 AdMob 유닛 활성화 대기 동안 릴리스(TestFlight)에서도 테스트 광고 사용.
    /// 유닛 활성화가 확인되면 false로 바꿔 실제 광고로 전환할 것. 디버그는 항상 테스트 광고.
    static let useTestAds = true

    private static let testInterstitialID = "ca-app-pub-3940256099942544/4411468910"  // Google 테스트 전면
    private static let testRewardedID = "ca-app-pub-3940256099942544/1712485313"      // Google 테스트 리워드
    private static let realInterstitialID = "ca-app-pub-1063542820867439/7673915387"
    private static let realRewardedID = "ca-app-pub-1063542820867439/1108507037"

    static var interstitialUnitID: String {
        #if DEBUG
        return testInterstitialID
        #else
        return useTestAds ? testInterstitialID : realInterstitialID
        #endif
    }

    static var rewardedUnitID: String {
        #if DEBUG
        return testRewardedID
        #else
        return useTestAds ? testRewardedID : realRewardedID
        #endif
    }

    private var interstitial: InterstitialAd?
    private var rewarded: RewardedAd?
    /// 리워드 광고가 로드되어 바로 보여줄 수 있는 상태인지 (힌트 소진 시 버튼 노출 조건).
    private(set) var rewardedReady = false

    private var started = false
    private var loadingInterstitial = false
    private var loadingRewarded = false
    private var onReward: (() -> Void)?

    /// 앱 시작 시 한 번: ATT 응답을 받은 뒤 SDK를 시작하고 광고를 미리 로드한다.
    /// (거부해도 비개인화 광고로 동작한다.)
    func start() {
        guard !started else { return }
        started = true
        ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
            Task { @MainActor in
                MobileAds.shared.start(completionHandler: nil)
                self?.loadInterstitial()
                self?.loadRewarded()
            }
        }
    }

    // MARK: - 전면 광고

    /// 하루 5문제 완료 직후 1회. 광고 제거 IAP 보유 시 표시하지 않는다.
    func showInterstitialAfterDayComplete(adsRemoved: Bool) {
        guard !adsRemoved, let interstitial, let root = Self.rootViewController() else { return }
        interstitial.fullScreenContentDelegate = self
        interstitial.present(from: root)
        self.interstitial = nil
    }

    private func loadInterstitial() {
        // async API 사용: 완료 핸들러 방식은 Swift 6 격리 검사(sending 'ad')에 걸린다.
        // no-fill/네트워크 오류 시 60초 간격으로 로드될 때까지 재시도한다.
        guard !loadingInterstitial, interstitial == nil else { return }
        loadingInterstitial = true
        Task {
            while interstitial == nil {
                interstitial = try? await InterstitialAd.load(
                    with: Self.interstitialUnitID, request: Request())
                if interstitial == nil {
                    try? await Task.sleep(for: .seconds(60))
                }
            }
            loadingInterstitial = false
        }
    }

    // MARK: - 리워드 광고 (힌트 충전, 보너스 문제)

    /// 시청 완료 시에만 onReward가 불린다 (중간에 닫으면 보상 없음).
    func showRewarded(onReward: @escaping () -> Void) {
        guard let rewarded, let root = Self.rootViewController() else { return }
        self.onReward = onReward
        rewarded.fullScreenContentDelegate = self
        self.rewarded = nil
        rewardedReady = false
        rewarded.present(from: root) { [weak self] in
            Task { @MainActor in
                self?.onReward?()
                self?.onReward = nil
            }
        }
    }

    private func loadRewarded() {
        guard !loadingRewarded, rewarded == nil else { return }
        loadingRewarded = true
        Task {
            while rewarded == nil {
                rewarded = try? await RewardedAd.load(
                    with: Self.rewardedUnitID, request: Request())
                if rewarded == nil {
                    try? await Task.sleep(for: .seconds(60))
                }
            }
            rewardedReady = true
            loadingRewarded = false
        }
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

extension AdsService: FullScreenContentDelegate {
    /// 광고가 닫히면 다음 광고를 미리 로드해 둔다.
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.loadInterstitial()
            self.loadRewarded()
        }
    }
}
