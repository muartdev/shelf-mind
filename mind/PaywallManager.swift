//
//  PaywallManager.swift
//  MindShelf
//
//  Created by Murat on 9.02.2026.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class PaywallManager {
    static let shared = PaywallManager()
    
    // For development - will integrate StoreKit later
    var isPremium: Bool {
        get { UserDefaults.standard.bool(forKey: "isPremium") }
        set { UserDefaults.standard.set(newValue, forKey: "isPremium") }
    }
    
    private init() {}
    
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
    
    // MARK: - Purchase (Placeholder)
    
    func purchasePremium() async throws {
        // TODO: Integrate StoreKit
        // For now, just unlock premium
        isPremium = true
    }
    
    func restorePurchases() async throws {
        // TODO: Integrate StoreKit restore
    }
}
