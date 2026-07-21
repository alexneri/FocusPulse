import Foundation
import StoreKit

/// StoreKit 2 manager (Story 6.1). Fetches products, tracks the Pro entitlement, handles purchases
/// and restores, and listens for transaction updates. `isPro` drives all feature gating.
@MainActor
final class StoreManager: ObservableObject {
    static let yearlyID = "moe.sei.PulseArc.pro.yearly"
    static let lifetimeID = "moe.sei.PulseArc.pro.lifetime"
    static let productIDs = [yearlyID, lifetimeID]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro = false
    @Published private(set) var loadFailed = false

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit { updatesTask?.cancel() }

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
            loadFailed = false
        } catch {
            products = []
            loadFailed = true
        }
    }

    /// Returns true if the purchase completed and unlocked Pro.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    return isPro
                }
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               Self.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPro = active
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}
