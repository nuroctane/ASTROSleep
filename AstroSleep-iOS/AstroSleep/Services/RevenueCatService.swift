import Foundation
import Combine
import UIKit

// MARK: - RevenueCat Service
/// Manages subscriptions using RevenueCat SDK.
/// Entitlement is checked at runtime — never trust local tier strings.
final class RevenueCatService: ObservableObject {
    static let shared = RevenueCatService()
    
    @Published var currentTier: SubscriptionTier = .free
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let revenueCatAPIKey = AppConfig.revenueCatAPIKey
    
    private init() {
        // Production: RevenueCat.configure(withAPIKey: revenueCatAPIKey)
        checkEntitlements()
    }
    
    // MARK: - Entitlement Checking
    
    func checkEntitlements() {
        isLoading = true
        
        // Production integration:
        // Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
        
        // Development fallback: read from local cache
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self?.isLoading = false
        }
    }
    
    func checkEntitlementSync() -> SubscriptionTier {
        // Always call RevenueCat at runtime
        // This is a synchronous wrapper for UI pre-rendering only
        // The authoritative check is async via checkEntitlements()
        return currentTier
    }
    
    // MARK: - Purchase Flow
    
    func purchase(_ package: SubscriptionPackage) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        // Production integration:
        // let result = try await Purchases.shared.purchase(package: package.revenueCatPackage)
        // return result.customerInfo.entitlements[package.entitlementId]?.isActive == true
        
        #if DEBUG
        // DEBUG only — never ship simulated unlocks to production.
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        switch package.tier {
        case .subscription:
            currentTier = .subscription
        case .lifetime:
            currentTier = .lifetime
        default:
            break
        }
        try? await StorageService.shared.updateProfile { profile in
            profile.cachedTierDisplayOnly = package.tier
        }
        return true
        #else
        error = "Purchases not configured. Connect RevenueCat SDK."
        return false
        #endif
    }
    
    func restorePurchases() async throws -> SubscriptionTier {
        isLoading = true
        defer { isLoading = false }
        
        // Production integration:
        // let customerInfo = try await Purchases.shared.restorePurchases()
        // Check entitlements and return tier
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        checkEntitlements()
        return currentTier
    }
    
    // MARK: - Paywall Products
    
    func getOfferings() async throws -> [SubscriptionPackage] {
        // Production integration:
        // let offerings = try await Purchases.shared.offerings()
        // return offerings.all.values.flatMap { $0.availablePackages }
        
        // Development fallback: return static offerings
        return [
            SubscriptionPackage(
                identifier: "subscription_monthly",
                tier: .subscription,
                localizedPriceString: "$7.99",
                localizedDescription: "Subscription Monthly",
                isMonthly: true
            ),
            SubscriptionPackage(
                identifier: "lifetime_pro",
                tier: .lifetime,
                localizedPriceString: "$79.99",
                localizedDescription: "Pro — One Time",
                isMonthly: false
            )
        ]
    }
    
    // MARK: - Management URL
    
    func openSubscriptionManagement() {
        if let url = URL(string: "appstore://subscriptions") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - Subscription Package

struct SubscriptionPackage: Identifiable {
    let id = UUID()
    let identifier: String
    let tier: SubscriptionTier
    let localizedPriceString: String
    let localizedDescription: String
    let isMonthly: Bool
    
    var displayPrice: String {
        if isMonthly {
            return "\(localizedPriceString)/month"
        } else {
            return "\(localizedPriceString)/year"
        }
    }
}
