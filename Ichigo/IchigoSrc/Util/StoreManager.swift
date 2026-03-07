import StoreKit

@Observable
@MainActor
final class StoreManager {

    // MARK: - Constants

    private static let productID = "com.ichigo.Ichigo.fullversion"
    private static let trialDays = 3
    private static let trialStartKey = "trial_start_date"

    // MARK: - Published State

    #if targetEnvironment(simulator)
    var isUnlocked: Bool { true }
    #else
    var isUnlocked: Bool { isPurchased || isTrialActive }
    #endif
    private(set) var isTrialActive = false
    private(set) var isPurchased = false
    private(set) var trialDaysRemaining = 0
    private(set) var product: Product?
    var isPurchasing = false
    var errorMessage: String?

    // MARK: - Private

    private nonisolated(unsafe) var updateTask: Task<Void, Never>?

    init() {
        updateTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await tx.finish()
                    await self?.refreshStatus()
                }
            }
        }
    }

    deinit {
        updateTask?.cancel()
    }

    // MARK: - Trial

    func ensureTrialStarted() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.trialStartKey) as? Date == nil {
            defaults.set(Date(), forKey: Self.trialStartKey)
        }
    }

    // MARK: - Refresh

    func refreshStatus() async {
        // 1. Check purchase entitlement
        var purchased = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == Self.productID,
               tx.revocationDate == nil {
                purchased = true
            }
        }
        isPurchased = purchased

        // 2. Calculate trial remaining
        if let startDate = UserDefaults.standard.object(forKey: Self.trialStartKey) as? Date {
            let calendar = Calendar.current
            let expiryDate = calendar.date(byAdding: .day, value: Self.trialDays, to: startDate) ?? Date()
            let remaining = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now),
                                                     to: calendar.startOfDay(for: expiryDate)).day ?? 0
            trialDaysRemaining = max(remaining, 0)
            isTrialActive = remaining > 0
        } else {
            isTrialActive = false
            trialDaysRemaining = 0
        }

        // 3. Fetch product
        if product == nil {
            if let products = try? await Product.products(for: [Self.productID]),
               let first = products.first {
                product = first
            }
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else { return }
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    await tx.finish()
                    isPurchased = true
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isPurchasing = false
    }

    // MARK: - Restore

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = error.localizedDescription
        }
        await refreshStatus()
    }
}
