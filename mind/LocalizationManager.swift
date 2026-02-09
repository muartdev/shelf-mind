//
//  LocalizationManager.swift
//  MindShelf
//
//  Created by Murat on 9.02.2026.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class LocalizationManager {
    static let shared = LocalizationManager()
    
    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.code, forKey: "app_language")
        }
    }
    
    enum AppLanguage: String, CaseIterable, Identifiable {
        case english = "English"
        case turkish = "Türkçe"
        
        var id: String { rawValue }
        
        var code: String {
            switch self {
            case .english: return "en"
            case .turkish: return "tr"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .turkish: return "🇹🇷"
            }
        }
    }
    
    private init() {
        // Load saved language
        if let savedCode = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage.allCases.first(where: { $0.code == savedCode }) {
            self.currentLanguage = language
        } else {
            // Default to English
            self.currentLanguage = .english
        }
    }
    
    func localizedString(_ key: String) -> String {
        return LocalizedStrings.get(key, language: currentLanguage)
    }
}

// MARK: - Localized Strings

struct LocalizedStrings {
    static func get(_ key: String, language: LocalizationManager.AppLanguage) -> String {
        switch language {
        case .english:
            return english[key] ?? key
        case .turkish:
            return turkish[key] ?? key
        }
    }
    
    // MARK: - English
    
    private static let english: [String: String] = [
        // Tab Bar
        "tab.bookmarks": "Bookmarks",
        "tab.statistics": "Statistics",
        "tab.settings": "Settings",
        
        // Main Screen
        "main.title": "MindShelf",
        "main.search": "Search bookmarks",
        "main.empty.title": "No Bookmarks Yet",
        "main.empty.message": "Start saving your favorite links",
        "main.filter.all": "All",
        
        // Add Bookmark
        "add.title": "Add Bookmark",
        "add.url": "URL",
        "add.url.placeholder": "Paste URL here",
        "add.title.field": "Title",
        "add.title.placeholder": "Enter title (auto-filled from URL)",
        "add.notes": "Notes (Optional)",
        "add.notes.placeholder": "Add notes...",
        "add.category": "Category",
        "add.save": "Save",
        "add.cancel": "Cancel",
        
        // Categories
        "category.general": "General",
        "category.x": "X",
        "category.instagram": "Instagram",
        "category.youtube": "YouTube",
        "category.article": "Article",
        "category.video": "Video",
        
        // Statistics
        "stats.title": "Statistics",
        "stats.total": "Total",
        "stats.read": "Read",
        "stats.toread": "To Read",
        "stats.progress": "Progress",
        "stats.complete": "Complete",
        "stats.activity": "Activity",
        "stats.last7days": "Last 7 days",
        "stats.categories": "Categories",
        "stats.types": "types",
        "stats.bookmarks": "bookmarks",
        
        // Settings
        "settings.title": "Settings",
        "settings.account": "Account",
        "settings.preferences": "Preferences",
        "settings.language": "Language",
        "settings.appearance": "Appearance",
        "settings.theme": "Theme",
        "settings.notifications": "Notifications",
        "settings.enable.notifications": "Enable Notifications",
        "settings.daily.reminder": "Daily Reminder",
        "settings.data": "Data",
        "settings.export": "Export Bookmarks",
        "settings.import": "Import Bookmarks",
        "settings.delete.all": "Delete All Bookmarks",
        "settings.statistics": "Statistics",
        "settings.total.bookmarks": "Total Bookmarks",
        "settings.unread": "Unread",
        "settings.about": "About",
        "settings.version": "Version",
        "settings.github": "GitHub",
        "settings.premium": "Premium",
        "settings.upgrade": "Upgrade to Premium",
        "settings.premium.active": "Premium Active",
        "settings.premium.desc": "Unlimited bookmarks, URL preview & more",
        "settings.premium.from": "From",
        "settings.signout": "Sign Out",
        
        // Premium
        "premium.title": "Unlock Premium",
        "premium.subtitle": "Get unlimited access to all features",
        "premium.start": "Start Premium",
        "premium.restore": "Restore Purchases",
        "premium.terms": "Terms of Service",
        "premium.privacy": "Privacy Policy",
        "premium.monthly": "Monthly",
        "premium.yearly": "Yearly",
        "premium.lifetime": "Lifetime",
        "premium.permonth": "per month",
        "premium.peryear": "per year",
        "premium.onetime": "one-time payment",
        "premium.save": "Save 44%",
        "premium.bestvalue": "Best Value",
        
        // Premium Features
        "feature.unlimited": "Unlimited Bookmarks",
        "feature.unlimited.desc": "Save as many bookmarks as you want",
        "feature.preview": "URL Preview",
        "feature.preview.desc": "Automatic title and image extraction",
        "feature.stats": "Advanced Statistics",
        "feature.stats.desc": "Detailed analytics and insights",
        "feature.themes": "Custom Themes",
        "feature.themes.desc": "More beautiful color schemes",
        "feature.sync": "Cloud Sync",
        "feature.sync.desc": "Access your bookmarks on all devices",
        
        // Auth
        "auth.signin": "Sign In",
        "auth.signup": "Sign Up",
        "auth.email": "Email",
        "auth.password": "Password",
        "auth.name": "Name",
        "auth.donthave": "Don't have an account? Sign Up",
        "auth.alreadyhave": "Already have an account? Sign In",
        "auth.secure": "Secure Authentication with Supabase",
        
        // Common
        "common.close": "Close",
        "common.done": "Done",
        "common.save": "Save",
        "common.cancel": "Cancel",
        "common.delete": "Delete",
        "common.open": "Open",
        "common.loading": "Loading...",
        "common.mark.read": "Mark as Read",
        "common.mark.unread": "Mark as Unread",
        "common.open.browser": "Open in Browser",
    ]
    
    // MARK: - Turkish
    
    private static let turkish: [String: String] = [
        // Tab Bar
        "tab.bookmarks": "Yer İmleri",
        "tab.statistics": "İstatistikler",
        "tab.settings": "Ayarlar",
        
        // Main Screen
        "main.title": "MindShelf",
        "main.search": "Yer imlerini ara",
        "main.empty.title": "Henüz Yer İmi Yok",
        "main.empty.message": "Favori bağlantılarını kaydetmeye başla",
        "main.filter.all": "Tümü",
        
        // Add Bookmark
        "add.title": "Yer İmi Ekle",
        "add.url": "URL",
        "add.url.placeholder": "URL'yi buraya yapıştır",
        "add.title.field": "Başlık",
        "add.title.placeholder": "Başlık girin (URL'den otomatik doldurulur)",
        "add.notes": "Notlar (İsteğe Bağlı)",
        "add.notes.placeholder": "Not ekle...",
        "add.category": "Kategori",
        "add.save": "Kaydet",
        "add.cancel": "İptal",
        
        // Categories
        "category.general": "Genel",
        "category.x": "X",
        "category.instagram": "Instagram",
        "category.youtube": "YouTube",
        "category.article": "Makale",
        "category.video": "Video",
        
        // Statistics
        "stats.title": "İstatistikler",
        "stats.total": "Toplam",
        "stats.read": "Okundu",
        "stats.toread": "Okunacak",
        "stats.progress": "İlerleme",
        "stats.complete": "Tamamlandı",
        "stats.activity": "Aktivite",
        "stats.last7days": "Son 7 gün",
        "stats.categories": "Kategoriler",
        "stats.types": "tip",
        "stats.bookmarks": "yer imi",
        
        // Settings
        "settings.title": "Ayarlar",
        "settings.account": "Hesap",
        "settings.preferences": "Tercihler",
        "settings.language": "Dil",
        "settings.appearance": "Görünüm",
        "settings.theme": "Tema",
        "settings.notifications": "Bildirimler",
        "settings.enable.notifications": "Bildirimleri Etkinleştir",
        "settings.daily.reminder": "Günlük Hatırlatıcı",
        "settings.data": "Veri",
        "settings.export": "Yer İmlerini Dışa Aktar",
        "settings.import": "Yer İmlerini İçe Aktar",
        "settings.delete.all": "Tüm Yer İmlerini Sil",
        "settings.statistics": "İstatistikler",
        "settings.total.bookmarks": "Toplam Yer İmi",
        "settings.unread": "Okunmamış",
        "settings.about": "Hakkında",
        "settings.version": "Sürüm",
        "settings.github": "GitHub",
        "settings.premium": "Premium",
        "settings.upgrade": "Premium'a Yükselt",
        "settings.premium.active": "Premium Aktif",
        "settings.premium.desc": "Sınırsız yer imi, URL önizleme ve daha fazlası",
        "settings.premium.from": "İtibaren",
        "settings.signout": "Çıkış Yap",
        
        // Premium
        "premium.title": "Premium'u Aç",
        "premium.subtitle": "Tüm özelliklere sınırsız erişim",
        "premium.start": "Premium'u Başlat",
        "premium.restore": "Satın Alımları Geri Yükle",
        "premium.terms": "Kullanım Koşulları",
        "premium.privacy": "Gizlilik Politikası",
        "premium.monthly": "Aylık",
        "premium.yearly": "Yıllık",
        "premium.lifetime": "Ömür Boyu",
        "premium.permonth": "aylık",
        "premium.peryear": "yıllık",
        "premium.onetime": "tek seferlik ödeme",
        "premium.save": "%44 Tasarruf",
        "premium.bestvalue": "En İyi Değer",
        
        // Premium Features
        "feature.unlimited": "Sınırsız Yer İmi",
        "feature.unlimited.desc": "İstediğin kadar yer imi kaydet",
        "feature.preview": "URL Önizleme",
        "feature.preview.desc": "Otomatik başlık ve resim çıkarma",
        "feature.stats": "Gelişmiş İstatistikler",
        "feature.stats.desc": "Detaylı analiz ve içgörüler",
        "feature.themes": "Özel Temalar",
        "feature.themes.desc": "Daha güzel renk şemaları",
        "feature.sync": "Bulut Senkronizasyonu",
        "feature.sync.desc": "Yer imlerine tüm cihazlardan eriş",
        
        // Auth
        "auth.signin": "Giriş Yap",
        "auth.signup": "Kayıt Ol",
        "auth.email": "E-posta",
        "auth.password": "Şifre",
        "auth.name": "Ad",
        "auth.donthave": "Hesabın yok mu? Kayıt Ol",
        "auth.alreadyhave": "Zaten hesabın var mı? Giriş Yap",
        "auth.secure": "Supabase ile Güvenli Kimlik Doğrulama",
        
        // Common
        "common.close": "Kapat",
        "common.done": "Tamam",
        "common.save": "Kaydet",
        "common.cancel": "İptal",
        "common.delete": "Sil",
        "common.open": "Aç",
        "common.loading": "Yükleniyor...",
        "common.mark.read": "Okundu Olarak İşaretle",
        "common.mark.unread": "Okunmadı Olarak İşaretle",
        "common.open.browser": "Tarayıcıda Aç",
    ]
}
