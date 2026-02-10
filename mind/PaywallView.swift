//
//  PaywallView.swift
//  MindShelf
//
//  Created by Murat on 9.02.2026.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    @State private var selectedProductID: PaywallManager.ProductID = .yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var isAnimating = false // Deprecated pulse animation

    
    private var paywall = PaywallManager.shared
    
    private var selectedProduct: Product? {
        paywall.products.first { $0.id == selectedProductID.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Features
                        featuresSection
                        
                        // Pricing
                        pricingSection
                        
                        // CTA
                        ctaButton
                        
                        // Footer
                        footerSection
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.localizedString("common.close")) {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: themeManager.currentTheme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(localization.localizedString("premium.title"))
                .font(.system(size: 36, weight: .bold, design: .rounded))
            
            Text(localization.localizedString("premium.subtitle"))
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(
                icon: "infinity",
                title: localization.localizedString("feature.unlimited"),
                description: localization.localizedString("feature.unlimited.desc")
            )
            
            FeatureRow(
                icon: "link.badge.plus",
                title: localization.localizedString("feature.preview"),
                description: localization.localizedString("feature.preview.desc")
            )
            
            FeatureRow(
                icon: "chart.bar.fill",
                title: localization.localizedString("feature.stats"),
                description: localization.localizedString("feature.stats.desc")
            )
            
            FeatureRow(
                icon: "icloud.fill",
                title: localization.localizedString("feature.sync"),
                description: localization.localizedString("feature.sync.desc")
            )
            
            FeatureRow(
                icon: "paintbrush.fill",
                title: localization.localizedString("feature.themes"),
                description: localization.localizedString("feature.themes.desc")
            )
        }
        .padding(.vertical)
    }
    
    private var pricingSection: some View {
        VStack(spacing: 12) {
            Text(localization.localizedString("settings.premium"))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                if paywall.products.isEmpty {
                    if paywall.isLoading {
                        ProgressView(localization.localizedString("paywall.loading"))
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            Text(localization.localizedString("paywall.error"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button(localization.localizedString("paywall.retry")) {
                                Task {
                                    await paywall.loadProducts()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                } else {
                    // Sort order: Yearly, Monthly, Lifetime
                    // or just sort by price descending? 
                    // Let's stick to a manual sort to ensure Yearly (Recommended) is top or middle.
                    // Common pattern: Yearly, Monthly, Lifetime
                    
                    let products = paywall.products.sorted { p1, p2 in
                        // Yearly first
                        if p1.id == PaywallManager.ProductID.yearly.rawValue { return true }
                        if p2.id == PaywallManager.ProductID.yearly.rawValue { return false }
                        // Then Monthly
                        if p1.id == PaywallManager.ProductID.monthly.rawValue { return true }
                        if p2.id == PaywallManager.ProductID.monthly.rawValue { return false }
                        return false
                    }
                    
                    ForEach(products) { product in
                        if let productID = PaywallManager.ProductID(rawValue: product.id) {
                            let isYearly = productID == .yearly
                            let isLifetime = productID == .lifetime
                            
                            PlanCard(
                                title: product.displayName,
                                price: product.displayPrice,
                                description: getDescription(for: productID),
                                isSelected: selectedProductID == productID,
                                isRecommended: isYearly,
                                isLifetime: isLifetime
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedProductID = productID
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getDescription(for productID: PaywallManager.ProductID) -> String {
        switch productID {
        case .yearly:
            return localization.localizedString("paywall.yearly.desc")
        case .monthly:
            return localization.localizedString("paywall.monthly.desc")
        case .lifetime:
            return localization.localizedString("premium.onetime")
        }
    }
    
    private var ctaButton: some View {
        VStack(spacing: 8) {
            Button(action: purchasePremium) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(localization.localizedString("paywall.start.premium"))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            themeManager.currentTheme.primaryColor,
                            themeManager.currentTheme.secondaryColor
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isPurchasing || selectedProduct == nil)
            .opacity(isPurchasing || selectedProduct == nil ? 0.5 : 1.0)
            .shadow(
                color: themeManager.currentTheme.primaryColor.opacity(0.3),
                radius: 10,
                y: 5
            )
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onAppear {
            // Default to Yearly if available
            if selectedProductID != .yearly {
                selectedProductID = .yearly
            }
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            Button(localization.localizedString("paywall.restore")) {
                restorePurchases()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            Text(localization.localizedString("paywall.cancel.anytime"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Actions
    
    private func purchasePremium() {
        guard let product = selectedProduct else { return }
        
        Task {
            isPurchasing = true
            errorMessage = nil
            defer { isPurchasing = false }
            
            do {
                try await paywall.purchase(product)
                dismiss()
            } catch {
                print("❌ Purchase failed: \(error)")
                errorMessage = localization.localizedString("paywall.failed")
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            errorMessage = nil
            do {
                try await PaywallManager.shared.restorePurchases()
                dismiss()
            } catch {
                print("❌ Restore failed: \(error)")
                errorMessage = localization.localizedString("paywall.failed")
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(.blue)
            .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let title: String
    let price: String
    let description: String
    let isSelected: Bool
    let isRecommended: Bool
    let isLifetime: Bool
    
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text(title)
                    .font(.headline)

                if isRecommended {
                    Text(localization.localizedString("paywall.most.popular"))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(Color.green)
                        .cornerRadius(8)
                    
                    Text(localization.localizedString("paywall.save"))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(Color.orange)
                        .cornerRadius(8)
                }
                
                if isLifetime {
                     Text(localization.localizedString("premium.bestvalue"))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(Color.blue)
                        .cornerRadius(8)
                }

                Spacer()

                Text(price)
                    .font(.title3.bold())
            }
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial.opacity(isSelected ? 1.0 : 0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? .blue : .clear, lineWidth: 2)
        )
        .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 10)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    PaywallView()
        .environment(ThemeManager())
}
