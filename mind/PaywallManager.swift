//
//  PaywallManager.swift
//  MindShelf
//
//  Created by Murat on 9.02.2026.
//

import Foundation
import SwiftUI
import StoreKit

@Observable
@MainActor
final class PaywallManager {
    static let shared = PaywallManager()
    
    // Premium status
    private(set) var isPremium: Bool = false
    private var isPremiumFromDatabase: Bool = false
    private var databaseExpirationDate: Date?
    
    // Available products
    private(set) var products: [Product] = []
    
    // Loading states
    private(set) var isLoading = false
    private(set) var purchaseError: String?
    
    // Product IDs (you'll need to create these in App Store Connect)
    enum ProductID: String {
        case monthly = "com.muartdev.mindshelf.premium.monthly"
        case yearly = "com.muartdev.mindshelf.premium.yearly"
        case lifetime = "com.muartdev.mindshelf.premium.lifetime"
    }
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePremiumStatus()
        }
    }
    
    // MARK: - Premium Features
    
    enum PremiumFeature {
        case unlimitedBookmarks
        case urlPreview
        case advancedStatistics
        case customThemes
        case cloudSync
        
        var title: String {
            switch self {
            case .unlimitedBookmarks: return "Unlimited Bookmarks"
            case .urlPreview: return "URL Preview"
            case .advancedStatistics: return "Advanced Statistics"
            case .customThemes: return "Custom Themes"
            case .cloudSync: return "Cloud Sync"
            }
        }
        
        var icon: String {
            switch self {
            case .unlimitedBookmarks: return "infinity"
            case .urlPreview: return "link.badge.plus"
            case .advancedStatistics: return "chart.bar.fill"
            case .customThemes: return "paintbrush.fill"
            case .cloudSync: return "icloud.fill"
            }
        }
    }
    
    // MARK: - Free Tier Limits
    
    static let freeBookmarkLimit = 10
    
    func canAddBookmark(currentCount: Int) -> Bool {
        if isPremium {
            return true
        }
        return currentCount < Self.freeBookmarkLimit
    }
    
    func checkFeatureAccess(_ feature: PremiumFeature) -> Bool {
        return isPremium
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        do {
            let productIDs: [ProductID] = [.monthly, .yearly, .lifetime]
            products = try await Product.products(for: productIDs.map { $0.rawValue })
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            purchaseError = "Failed to load products"
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Check verification
            let transaction = try checkVerified(verification)
            
            // Update premium status
            await updatePremiumStatus()
            
            // Finish the transaction
            await transaction.finish()
            
            print("✅ Purchase successful")
            
        case .userCancelled:
            print("⚠️ User cancelled purchase")
            
        case .pending:
            print("⏳ Purchase pending")
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updatePremiumStatus()
            print("✅ Purchases restored")
        } catch {
            print("❌ Restore failed: \(error)")
            purchaseError = "Failed to restore purchases"
            throw error
        }
    }
    
    // MARK: - Check Premium Status
    
    // Premium details
    private(set) var premiumExpirationDate: Date?
    private(set) var premiumPurchaseDate: Date?
    
    // MARK: - Check Premium Status
    
    func updatePremiumStatus() async {
        var hasPremiumStoreKit = false
        var latestTransaction: StoreKit.Transaction?
        
        // Check all transactions
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                // Check if it's a premium product
                if ProductID(rawValue: transaction.productID) != nil {
                    hasPremiumStoreKit = true
                    latestTransaction = transaction
                    
                    // If it's a subscription, we might want the one with the latest expiration
                    if let expiration = transaction.expirationDate {
                        if latestTransaction?.expirationDate == nil || expiration > latestTransaction!.expirationDate! {
                            latestTransaction = transaction
                        }
                    }
                }
            }
        }
        
        // Apply StoreKit results
        if let transaction = latestTransaction {
            premiumExpirationDate = transaction.expirationDate
            premiumPurchaseDate = transaction.purchaseDate
        } else {
            premiumExpirationDate = nil
            premiumPurchaseDate = nil
        }
        
        // FINAL STATUS: StoreKit OR Database
        // Database acts as a fallback for cross-Apple-ID/Cross-Device persistence
        self.isPremium = hasPremiumStoreKit || isPremiumFromDatabase
        
        // SYNC TO DATABASE
        // If we have a logged in user, sync their premium status to Supabase
        if let userId = UserDefaults.standard.string(forKey: "userId"), let userUUID = UUID(uuidString: userId) {
            // Only sync if StoreKit has a verified status
            if hasPremiumStoreKit {
                Task {
                    do {
                        try await SupabaseManager.shared.updateUserPremiumStatus(
                            userId: userUUID,
                            isPremium: true,
                            expirationDate: premiumExpirationDate
                        )
                        print("✅ Premium status synced to Supabase")
                    } catch {
                        print("❌ Failed to sync premium status to Supabase: \(error)")
                    }
                }
            }
        }
        
        print(isPremium ? "✅ User is Premium" : "⚠️ User is Free")
        if let expiration = premiumExpirationDate ?? databaseExpirationDate {
            print("📅 Expires: \(expiration)")
        }
    }
    
    func setPremiumFromDatabase(isPremium: Bool, expirationDate: Date?) {
        self.isPremiumFromDatabase = isPremium
        self.databaseExpirationDate = expirationDate
        
        // Re-evaluate overall status
        Task {
            await updatePremiumStatus()
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { @MainActor in
            // Listen for transaction updates
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Update premium status
                    await self.updatePremiumStatus()
                    
                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Helpers
    
    func priceString(for product: Product) -> String {
        return product.displayPrice
    }
}

// MARK: - Store Error

enum StoreError: Error {
    case failedVerification
}
