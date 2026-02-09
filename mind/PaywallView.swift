//
//  PaywallView.swift
//  MindShelf
//
//  Created by Murat on 9.02.2026.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedPlan: PricingPlan = .yearly
    @State private var isPurchasing = false
    
    enum PricingPlan {
        case monthly
        case yearly
        
        var price: String {
            switch self {
            case .monthly: return "$2.99"
            case .yearly: return "$19.99"
            }
        }
        
        var period: String {
            switch self {
            case .monthly: return "per month"
            case .yearly: return "per year"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Save 44%"
            }
        }
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
                PricingCard(
                    plan: .monthly,
                    isSelected: selectedPlan == .monthly,
                    action: { selectedPlan = .monthly }
                )
                
                PricingCard(
                    plan: .yearly,
                    isSelected: selectedPlan == .yearly,
                    action: { selectedPlan = .yearly }
                )
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
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isPurchasing)
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
        Task {
            isPurchasing = true
            defer { isPurchasing = false }
            
            do {
                try await PaywallManager.shared.purchasePremium()
                dismiss()
            } catch {
                print("❌ Purchase failed: \(error)")
            }
        }
    }
    
    private func restorePurchases() {
        Task {
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

// MARK: - Pricing Card

struct PricingCard: View {
    let plan: PaywallView.PricingPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan == .monthly ? "Monthly" : "Yearly")
                            .font(.headline)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green, in: Capsule())
                        }
                    }
                    
                    Text(plan.period)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(plan.price)
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
