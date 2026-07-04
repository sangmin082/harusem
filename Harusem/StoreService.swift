import Foundation
import Observation
import StoreKit

/// StoreKit 2 기반 IAP: 광고 제거 + 아카이브 잠금 해제 (둘 다 비소모성).
@Observable
@MainActor
final class StoreService {
    static let removeAdsID = "com.harusem.iap.removeads"
    static let archiveID = "com.harusem.iap.archive"
    static let allIDs: Set<String> = [removeAdsID, archiveID]

    private(set) var products: [Product] = []
    private(set) var purchasedIDs: Set<String> = []
    private(set) var isLoading = false

    var ownsRemoveAds: Bool { purchasedIDs.contains(Self.removeAdsID) }
    var ownsArchive: Bool { purchasedIDs.contains(Self.archiveID) }

    private var updatesTask: Task<Void, Never>?

    /// 앱 시작 시 한 번 호출: 상품 로드 + 소유권 확인 + 트랜잭션 업데이트 구독.
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        products = ((try? await Product.products(for: Self.allIDs)) ?? [])
            .sorted { $0.id < $1.id }
    }

    func refreshEntitlements() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                owned.insert(transaction.productID)
            }
        }
        purchasedIDs = owned
    }

    func purchase(_ product: Product) async {
        guard let result = try? await product.purchase() else { return }
        if case .success(let verification) = result,
           case .verified(let transaction) = verification {
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }
}
