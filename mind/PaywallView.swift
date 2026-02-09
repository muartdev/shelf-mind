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
    @State private var selectedProductID: PaywallManager.ProductID = .yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var isAnimating = false
    
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
                    Button("Close") {
                        dismiss()
                    }
                }
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
            
            Text("Unlock Premium")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            
            Text("Get unlimited access to all features")
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
                title: "Unlimited Bookmarks",
                description: "Save as many bookmarks as you want"
            )
            
            FeatureRow(
                icon: "link.badge.plus",
                title: "Smart URL Preview",
                description: "Automatic title and thumbnail extraction"
            )
            
            FeatureRow(
                icon: "chart.bar.fill",
                title: "Advanced Statistics",
                description: "Detailed analytics and insights"
            )
            
            FeatureRow(
                icon: "icloud.fill",
                title: "Cloud Sync",
                description: "Access your bookmarks on all devices"
            )
            
            FeatureRow(
                icon: "paintbrush.fill",
                title: "Custom Themes",
                description: "More beautiful color schemes"
            )
        }
        .padding(.vertical)
    }
    
    private var pricingSection: some View {
        VStack(spacing: 12) {
            Text("Choose Your Plan")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                if paywall.products.isEmpty {
                    if paywall.isLoading {
                        ProgressView("Loading plans...")
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            Text("Unable to load plans")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button("Retry") {
                                Task {
                                    await paywall.loadProducts()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                } else {
                    ForEach(paywall.products, id: \.id) { product in
                        if let productID = PaywallManager.ProductID(rawValue: product.id) {
                            ProductCard(
                                product: product,
                                productID: productID,
                                isSelected: selectedProductID == productID,
                                action: { selectedProductID = productID }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var ctaButton: some View {
        Button(action: purchasePremium) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start Premium")
                        .font(.headline)
                        .fontWeight(.bold)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
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
        .shadow(
            color: themeManager.currentTheme.primaryColor.opacity(isAnimating ? 0.6 : 0.3),
            radius: isAnimating ? 15 : 10,
            y: 5
        )
        .opacity(isPurchasing || selectedProduct == nil ? 0.6 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                restorePurchases()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            Text("Cancel anytime. Auto-renewable subscription.")
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
                errorMessage = "Purchase failed. Please try again."
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

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let productID: PaywallManager.ProductID
    let isSelected: Bool
    let action: () -> Void
    
    private var title: String {
        switch productID {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }
    
    private var period: String {
        switch productID {
        case .monthly: return "per month"
        case .yearly: return "per year"
        case .lifetime: return "one-time payment"
        }
    }
    
    private var savings: String? {
        switch productID {
        case .monthly: return nil
        case .yearly: return "Save 44%"
        case .lifetime: return "Best Value"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        
                        if let savings = savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green, in: Capsule())
                        }
                    }
                    
                    Text(period)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding()
            .background(
                isSelected ? .ultraThinMaterial : .thinMaterial,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? .blue : .white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
        .environment(ThemeManager())
}
