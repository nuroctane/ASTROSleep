import SwiftUI

// MARK: - Paywall View
struct PaywallView: View {
    let triggerFeature: String
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var revenueCat: RevenueCatService
    @Environment(\.dismiss) private var dismiss
    
    @State private var offerings: [SubscriptionPackage] = []
    @State private var isLoading = false
    @State private var selectedProduct: SubscriptionPackage?
    @State private var showingRestoreAlert = false
    @State private var restoreResult: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Feature comparison
                    featureComparison
                    
                    // Product cards
                    productCards
                    
                    // Legal footer
                    legalFooter
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            loadOfferings()
        }
        .overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK") {}
        } message: {
            Text(restoreResult ?? "")
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(ThemeService.shared.accentColor)
            
            Text("Unlock Your Full Potential")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get personalized astrological sleep sessions with advanced features.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Feature Comparison
    private var featureComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's Included")
                .font(.headline)
            
            VStack(spacing: 0) {
                FeatureRow(
                    feature: "Sound Recommendations",
                    free: "✓",
                    sub: "✓",
                    pro: "✓"
                )
                
                FeatureRow(
                    feature: "Combo Layers",
                    free: "2",
                    sub: "7",
                    pro: "7"
                )
                
                FeatureRow(
                    feature: "Transit Scoring",
                    free: "✓",
                    sub: "✓",
                    pro: "✓"
                )
                
                FeatureRow(
                    feature: "Oscillation / LFO",
                    free: "✓",
                    sub: "✓",
                    pro: "✓"
                )
                
                FeatureRow(
                    feature: "Saved Playlists",
                    free: "5",
                    sub: "∞",
                    pro: "∞"
                )
                
                FeatureRow(
                    feature: "Session History",
                    free: "14d",
                    sub: "∞",
                    pro: "∞"
                )
                
                FeatureRow(
                    feature: "Custom Voice Recording",
                    free: "—",
                    sub: "✓",
                    pro: "✓"
                )
                
                FeatureRow(
                    feature: "Future Features",
                    free: "—",
                    sub: "✓",
                    pro: "✓"
                )
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Product Cards
    private var productCards: some View {
        VStack(spacing: 12) {
            // Subscription Card
            productCard(
                tier: .subscription,
                title: "Subscription",
                description: "Monthly access to enhanced features",
                color: .blue,
                isPopular: false
            )
            
            // Lifetime Pro Card
            productCard(
                tier: .lifetime,
                title: "Pro — One Time",
                description: "Full app forever. All future updates included.",
                color: ThemeService.shared.accentColor,
                isPopular: true
            )
        }
    }
    
    private func productCard(tier: SubscriptionTier, title: String, description: String, color: Color, isPopular: Bool) -> some View {
        let products = offerings.filter { $0.tier == tier }
        let monthly = products.first { $0.isMonthly }
        let annual = products.first { !$0.isMonthly }
        
        return VStack(spacing: 12) {
            if isPopular {
                Text("Best Value")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(color)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if let monthly = monthly {
                        VStack(alignment: .trailing) {
                            Text(monthly.localizedPriceString)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("/month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let annual = annual {
                    HStack {
                        Text("\(annual.localizedPriceString)/year")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Save 25%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Button(action: {
                    if let product = monthly ?? annual {
                        purchase(product)
                    }
                }) {
                    Text(tier == .lifetime ? "Unlock Pro Forever" : "Start 7-Day Free Trial")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(color)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isPopular ? color : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Legal Footer
    private var legalFooter: some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") {
                restorePurchases()
            }
            .font(.subheadline)
            .foregroundColor(ThemeService.shared.accentColor)
            
            Text("Subscription auto-renews monthly. Cancel anytime in App Store settings. One-time Pro is a non-consumable in-app purchase.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Actions
    private func loadOfferings() {
        Task {
            do {
                let products = try await revenueCat.getOfferings()
                await MainActor.run {
                    self.offerings = products
                }
            } catch {
                print("Failed to load offerings: \(error)")
            }
        }
    }
    
    private func purchase(_ product: SubscriptionPackage) {
        isLoading = true
        Task {
            do {
                let success = try await revenueCat.purchase(product)
                await MainActor.run {
                    isLoading = false
                    if success {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    appState.errorMessage = "Purchase failed. Please try again."
                }
            }
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        Task {
            do {
                let tier = try await revenueCat.restorePurchases()
                await MainActor.run {
                    isLoading = false
                    restoreResult = tier > .free ?
                        "Your \(tier.displayName) plan has been restored." :
                        "No active subscription found."
                    showingRestoreAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    restoreResult = "No active subscription found."
                    showingRestoreAlert = true
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: String
    let free: String
    let sub: String
    let pro: String
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 0) {
                Text(free)
                    .font(.caption)
                    .frame(width: 50, alignment: .center)
                
                Text(sub)
                    .font(.caption)
                    .frame(width: 50, alignment: .center)
                    .foregroundColor(.blue)
                
                Text(pro)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 60, alignment: .center)
                    .foregroundColor(ThemeService.shared.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
    }
}
