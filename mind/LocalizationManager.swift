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
    
    var onLanguageChange: ((AppLanguage) -> Void)?
    
    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.code, forKey: "app_language")
            // Sync to app group for Share Extension
            UserDefaults(suiteName: "group.com.muartdev.mind")?.set(currentLanguage.code, forKey: "app_language")
            onLanguageChange?(currentLanguage)
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
        // Load saved language (check app group first for Share Extension consistency)
        let savedCode = UserDefaults(suiteName: "group.com.muartdev.mind")?.string(forKey: "app_language")
            ?? UserDefaults.standard.string(forKey: "app_language")
        if let code = savedCode,
           let language = AppLanguage.allCases.first(where: { $0.code == code }) {
            self.currentLanguage = language
        } else {
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
            // Fallback to English if Turkish translation is missing
            return turkish[key] ?? english[key] ?? key
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
        "main.filter.unread": "Unread",
        "main.filter.favorites": "Favorites",
        "main.empty.favorites.title": "No Favorites Yet",
        "main.empty.favorites.message": "Star bookmarks to see them here",
        "main.load.more": "Load More",
        "sort.date.newest": "Date (Newest)",
        "sort.date.oldest": "Date (Oldest)",
        "sort.title.az": "Title (A-Z)",
        "sort.title.za": "Title (Z-A)",
        "sort.category": "Category",
        "sort.read.first": "Read First",
        "sort.unread.first": "Unread First",
        "main.empty.filtered.title": "No Bookmarks in This Category",
        "main.empty.filtered.message": "Try adding a bookmark with this category or clear the filter to see all",
        "main.empty.unread.title": "All Caught Up!",
        "main.empty.unread.message": "You've read all your bookmarks. Great job!",
        "main.empty.default.title": "No Bookmarks Yet",
        "main.empty.default.message": "Save interesting content from X, articles, and videos to read later",
        "main.clear.filters": "Clear Filters",
        "main.add.first": "Add Your First Bookmark",
        
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
        "stats.days.7": "7 days",
        "stats.days.14": "14 days",
        "stats.days.30": "30 days",
        "stats.categories": "Categories",
        "stats.types": "types",
        "stats.bookmarks": "bookmarks",
        "stats.insights": "Insights",
        "stats.pace": "Pace",
        "stats.most.active": "Most Active",
        "stats.streak": "Streak",
        "stats.streak.days": "%d days",
        "stats.no.streak": "Start reading!",
        "stats.bookmarks.week": "bookmarks/week",

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
        "settings.guest.headline": "On-device only",
        "settings.guest.detail": "Bookmarks are stored on this iPhone. Sign in to sync across devices and the web app.",
        "settings.signin.cta": "Sign in or create account",
        
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
        "auth.or": "or",
        "auth.continue.guest": "Continue without account",
        "auth.continue.guest.hint": "Bookmarks are saved on this device only. Sign in anytime to sync with the web and other devices.",
        "auth.secure": "Secure Authentication with Supabase",
        "auth.subtitle": "Save and organize your favorite content",
        
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
        "common.favorite": "Add to Favorites",
        "common.unfavorite": "Remove from Favorites",
        
        // Paywall UI (New)
        "paywall.most.popular": "Most Popular",
        "paywall.recommended": "Recommended",
        "paywall.yearly.desc": "Best value for long-term use",
        "paywall.monthly.desc": "Pay monthly, cancel anytime",
        "paywall.start.premium": "Start Premium",
        "paywall.restore": "Restore Purchases",
        "paywall.cancel.anytime": "Cancel anytime. Auto-renewable subscription.",
        "paywall.loading": "Loading plans...",
        "paywall.error": "Unable to load plans",
        "paywall.retry": "Retry",
        "paywall.failed": "Purchase failed. Please try again.",
        "paywall.save": "Save 64%",
        
        // Account Deletion
        "settings.member.since": "Member Since",
        "settings.renews.on": "Renews/Expires",
        "settings.delete.account": "Delete Account",
        "settings.delete.account.message": "Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.",
        "settings.delete.confirm": "Delete My Account",

        // Delete All Bookmarks
        "settings.delete.all.confirm": "Delete All",
        "settings.delete.all.message": "This action cannot be undone. All your bookmarks will be permanently deleted.",

        // Themes
        "theme.blue.purple": "Blue Purple",
        "theme.orange.pink": "Orange Pink",
        "theme.light": "Light",
        "theme.dark": "Dark",
        
        // Auth Errors
        "auth.error.invalid_credentials": "Email or password is incorrect. Please check and try again.",
        "auth.error.missing_email": "Missing email or phone number",
        "auth.error.password_too_short": "Password should be at least 6 characters",
        "auth.error.already_registered": "User already registered",
        "auth.error.email_not_confirmed": "Please verify your email before signing in.",
        "auth.error.profile_missing": "Account profile not found. Please try again or contact support.",
        "auth.error.network": "Network error. Please check your connection.",
        "auth.error.unknown": "An unknown error occurred",
        
        // Email Verification
        "auth.verify.title": "Verify your email",
        "auth.verify.message": "We sent a verification code. Enter the latest code to continue.",
        "auth.verify.code.placeholder": "Verification code",
        "auth.verify.button": "Verify code",
        "auth.verify.resend": "Resend verification email",
        "auth.verify.sent": "Verification code sent.",
        "auth.verify.success": "Email verified. You can sign in now.",
        "auth.verify.change_email": "Change email",
        "auth.verify.resend_in": "Resend in %ds",
        "auth.forgot": "Forgot password?",
        "auth.reset.title": "Reset Password",
        "auth.reset.subtitle": "We’ll email you a link to reset your password.",
        "auth.reset.send": "Send Reset Link",
        "auth.reset.sent": "Reset email sent. Check your inbox.",
        
        // OTP Errors
        "auth.error.invalid_code": "Invalid or expired verification code. Please use the latest code.",
        "auth.error.rate_limit": "Too many requests. Please wait and try again.",
        "auth.error.resend_wait": "Please wait before requesting another code.",
        
        // Bookmark Detail
        "detail.title": "Title",
        "detail.url": "URL",
        "detail.notes": "Notes",
        "detail.tags": "Tags",
        "detail.add.tag": "Add tag",
        "detail.edit": "Edit Bookmark",
        "detail.view": "Bookmark",
        "detail.delete.confirm": "Delete Bookmark",
        "detail.delete.message": "Are you sure you want to delete this bookmark? This action cannot be undone.",
        "detail.mark.read": "Mark as Read",
        "detail.mark.unread": "Mark as Unread",
        "detail.open.browser": "Open in Browser",
        "detail.share": "Share",
        "detail.set.reminder": "Set Reminder",
        "detail.select.time": "Select Time",
        "detail.added": "Added",
        "detail.time": "Time",
        
        // Add Bookmark Errors
        "add.preview.tap": "Tap to use preview",
        "add.error.title": "Please enter a title",
        "add.error.url": "Please enter a URL",
        "add.error.url.invalid": "Please enter a valid URL",
        "add.error.duplicate": "This URL is already saved.",
        "error.sync.delete": "Could not delete on server",
        "error.sync.update": "Could not update on server",
        "add.error.duplicate_with_date": "This URL is already saved (%@).",
        
        // Premium Management
        "settings.premium.manage": "Manage Subscription",
        "settings.premium.manage.desc": "View and manage your subscription on App Store",
        "settings.premium.benefits": "Premium Benefits",
        "settings.premium.status.active": "Active",
        "settings.premium.status.cancelled": "Cancelled",
        "settings.premium.expiration.desc": "You have access to all features until this date.",
        "settings.premium.cancellation.title": "How to Cancel?",
        "settings.premium.cancellation.desc": "You can manage or cancel your subscription at any time through your App Store account settings.",

        // Privacy & Terms
        "settings.privacy.policy": "Privacy Policy",
        "settings.terms": "Terms of Service",

        // Notifications
        "notification.daily.body": "Check out your bookmarks and catch up on your reading!",

        // Onboarding
        "onboarding.page1.title": "Save Anything",
        "onboarding.page1.desc": "Bookmark articles, videos, and posts from X. Never lose track of interesting content again.",
        "onboarding.page2.title": "Stay Organized",
        "onboarding.page2.desc": "Simple categories and tags keep everything in its place. Find what you need, when you need it.",
        "onboarding.page3.title": "Read Later",
        "onboarding.page3.desc": "Mark as read, track your progress. Turn saved content into knowledge.",
        "onboarding.skip": "Skip",
        "onboarding.next": "Next",
        "onboarding.start": "Get Started",

        // App Errors
        "error.config.title": "Configuration Error",
        "error.config.message": "App configuration is missing. Please contact support.",
        "error.database.title": "Database Error",
        "error.database.message": "Local storage could not be loaded. Your data will not be saved between sessions. Please restart the app.",

        // URL Preview Premium Upsell
        "preview.premium.title": "URL Preview is a Premium feature",
        "preview.premium.desc": "Upgrade to get automatic title & image extraction for all bookmarks",
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
        "main.filter.unread": "Okunmamış",
        "main.filter.favorites": "Favoriler",
        "main.empty.favorites.title": "Henüz Favori Yok",
        "main.empty.favorites.message": "Favorilere eklemek için yer imlerine yıldız verin",
        "main.load.more": "Daha Fazla Yükle",
        "sort.date.newest": "Tarih (Yeniden eskiye)",
        "sort.date.oldest": "Tarih (Eskiden yeniye)",
        "sort.title.az": "Başlık (A-Z)",
        "sort.title.za": "Başlık (Z-A)",
        "sort.category": "Kategori",
        "sort.read.first": "Okunanlar önce",
        "sort.unread.first": "Okunmayanlar önce",
        "main.empty.filtered.title": "Bu Kategoride Yer İmi Yok",
        "main.empty.filtered.message": "Bu kategoriyle bir yer imi ekleyin veya tümünü görmek için filtreyi temizleyin",
        "main.empty.unread.title": "Hepsi Tamam!",
        "main.empty.unread.message": "Tüm yer imlerinizi okudunuz. Harika!",
        "main.empty.default.title": "Henüz Yer İmi Yok",
        "main.empty.default.message": "X, makaleler ve videolardan ilginç içerikleri daha sonra okumak için kaydedin",
        "main.clear.filters": "Filtreleri Temizle",
        "main.add.first": "İlk Yer İminizi Ekleyin",
        
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
        "stats.days.7": "7 gün",
        "stats.days.14": "14 gün",
        "stats.days.30": "30 gün",
        "stats.categories": "Kategoriler",
        "stats.types": "tip",
        "stats.bookmarks": "yer imi",
        "stats.insights": "İçgörüler",
        "stats.pace": "Hız",
        "stats.most.active": "En Aktif",
        "stats.streak": "Seri",
        "stats.streak.days": "%d gün",
        "stats.no.streak": "Okumaya başla!",
        "stats.bookmarks.week": "yer imi/hafta",

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
        "settings.guest.headline": "Yalnızca bu cihazda",
        "settings.guest.detail": "Yer imleri bu iPhone'da saklanır. Diğer cihazlar ve web uygulamasıyla senkron için giriş yap.",
        "settings.signin.cta": "Giriş yap veya hesap oluştur",
        
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
        "auth.or": "veya",
        "auth.continue.guest": "Hesap oluşturmadan devam et",
        "auth.continue.guest.hint": "Yer imleri yalnızca bu cihazda saklanır. Web ve diğer cihazlarla senkron için istediğinde giriş yapabilirsin.",
        "auth.secure": "Supabase ile Güvenli Kimlik Doğrulama",
        "auth.subtitle": "Favori içeriklerini kaydet ve düzenle",
        
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
        "common.favorite": "Favorilere Ekle",
        "common.unfavorite": "Favorilerden Çıkar",
        
        // Paywall UI (New)
        "paywall.most.popular": "En Popüler",
        "paywall.recommended": "Önerilen",
        "paywall.yearly.desc": "Uzun süreli kullanım için en iyi değer",
        "paywall.monthly.desc": "Aylık öde, istediğin zaman iptal et",
        "paywall.start.premium": "Premium'u Başlat",
        "paywall.restore": "Satın Alımları Geri Yükle",
        "paywall.cancel.anytime": "İstediğin zaman iptal et. Otomatik yenilenen abonelik.",
        "paywall.loading": "Planlar yükleniyor...",
        "paywall.error": "Planlar yüklenemedi",
        "paywall.retry": "Tekrar Dene",
        "paywall.failed": "Satın alma başarısız. Lütfen tekrar dene.",
        "paywall.save": "%64 Tasarruf",
        
        // Account Deletion
        "settings.member.since": "Üyelik Başlangıcı",
        "settings.renews.on": "Yenileme/Bitiş",
        "settings.delete.account": "Hesabı Sil",
        "settings.delete.account.message": "Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz kalıcı olarak silinecektir.",
        "settings.delete.confirm": "Hesabımı Sil",

        // Delete All Bookmarks
        "settings.delete.all.confirm": "Tümünü Sil",
        "settings.delete.all.message": "Bu işlem geri alınamaz. Tüm yer imleriniz kalıcı olarak silinecektir.",

        // Themes
        "theme.blue.purple": "Mavi Mor",
        "theme.orange.pink": "Turuncu Pembe",
        "theme.light": "Açık",
        "theme.dark": "Koyu",
        
        // Auth Errors
        "auth.error.invalid_credentials": "E-posta veya şifre hatalı. Lütfen kontrol edip tekrar dene.",
        "auth.error.missing_email": "E-posta veya telefon numarası eksik",
        "auth.error.password_too_short": "Şifre en az 6 karakter olmalıdır",
        "auth.error.already_registered": "Kullanıcı zaten kayıtlı",
        "auth.error.email_not_confirmed": "Giriş yapmadan önce e-postanı doğrulamalısın.",
        "auth.error.profile_missing": "Hesap profili bulunamadı. Lütfen tekrar dene veya destekle iletişime geç.",
        "auth.error.network": "Ağ hatası. Lütfen bağlantınızı kontrol edin.",
        "auth.error.unknown": "Bilinmeyen bir hata oluştu",
        
        // Email Verification
        "auth.verify.title": "E-postanı doğrula",
        "auth.verify.message": "Doğrulama kodu gönderdik. Devam etmek için en son gelen kodu gir.",
        "auth.verify.code.placeholder": "Doğrulama kodu",
        "auth.verify.button": "Kodu doğrula",
        "auth.verify.resend": "Doğrulama e-postasını tekrar gönder",
        "auth.verify.sent": "Doğrulama kodu gönderildi.",
        "auth.verify.success": "E-posta doğrulandı. Giriş yapabilirsin.",
        "auth.verify.change_email": "E-postayı değiştir",
        "auth.verify.resend_in": "%ds sonra tekrar gönder",
        "auth.forgot": "Şifremi unuttum",
        "auth.reset.title": "Şifreyi Sıfırla",
        "auth.reset.subtitle": "Şifreni sıfırlaman için e‑posta göndereceğiz.",
        "auth.reset.send": "Sıfırlama Bağlantısı Gönder",
        "auth.reset.sent": "E‑posta gönderildi. Lütfen gelen kutunu kontrol et.",
        
        // OTP Errors
        "auth.error.invalid_code": "Doğrulama kodu geçersiz veya süresi dolmuş. En son gelen kodu kullan.",
        "auth.error.rate_limit": "Çok fazla istek yapıldı. Lütfen biraz bekleyip tekrar dene.",
        "auth.error.resend_wait": "Yeni kod istemeden önce biraz beklemelisin.",
        
        // Bookmark Detail
        "detail.title": "Başlık",
        "detail.url": "URL",
        "detail.notes": "Notlar",
        "detail.tags": "Etiketler",
        "detail.add.tag": "Etiket ekle",
        "detail.edit": "Yer İmini Düzenle",
        "detail.view": "Yer İmi",
        "detail.delete.confirm": "Yer İmini Sil",
        "detail.delete.message": "Bu yer imini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
        "detail.mark.read": "Okundu Olarak İşaretle",
        "detail.mark.unread": "Okunmadı Olarak İşaretle",
        "detail.open.browser": "Tarayıcıda Aç",
        "detail.share": "Paylaş",
        "detail.set.reminder": "Hatırlatıcı Ayarla",
        "detail.select.time": "Zaman Seç",
        "detail.added": "Eklendi",
        "detail.time": "Saat",
        
        // Add Bookmark Errors
        "add.preview.tap": "Önizlemeyi kullanmak için dokunun",
        "add.error.title": "Lütfen bir başlık girin",
        "add.error.url": "Lütfen bir URL girin",
        "add.error.url.invalid": "Lütfen geçerli bir URL girin",
        "add.error.duplicate": "Bu URL zaten kaydedilmiş.",
        "error.sync.delete": "Sunucuda silinemedi",
        "error.sync.update": "Sunucuda güncellenemedi",
        "add.error.duplicate_with_date": "Bu URL zaten kaydedilmiş (%@).",

        // Premium Management
        "settings.premium.manage": "Aboneliği Yönet",
        "settings.premium.manage.desc": "App Store üzerinden aboneliğinizi dondurun veya iptal edin",
        "settings.premium.benefits": "Premium Avantajları",
        "settings.premium.status.active": "Aktif",
        "settings.premium.status.cancelled": "İptal Edildi",
        "settings.premium.expiration.desc": "Bu tarihe kadar tüm premium özellikleri kullanmaya devam edebilirsiniz.",
        "settings.premium.cancellation.title": "Nasıl İptal Edilir?",
        "settings.premium.cancellation.desc": "Aboneliğinizi istediğiniz zaman App Store hesap ayarlarınız üzerinden yönetebilir veya iptal edebilirsiniz.",

        // Privacy & Terms
        "settings.privacy.policy": "Gizlilik Politikası",
        "settings.terms": "Kullanım Koşulları",

        // Notifications
        "notification.daily.body": "Yer imlerini kontrol et ve okumalarına devam et!",

        // Onboarding
        "onboarding.page1.title": "Her Şeyi Kaydet",
        "onboarding.page1.desc": "Makaleler, videolar ve X gönderilerini kaydet. İlginç içerikleri bir daha kaybetme.",
        "onboarding.page2.title": "Düzenli Kal",
        "onboarding.page2.desc": "Basit kategoriler ve etiketler her şeyi yerli yerinde tutar. İhtiyacın olanı, ihtiyacın olduğunda bul.",
        "onboarding.page3.title": "Sonra Oku",
        "onboarding.page3.desc": "Okundu olarak işaretle, ilerleni takip et. Kaydettiğin içerikleri bilgiye dönüştür.",
        "onboarding.skip": "Geç",
        "onboarding.next": "İleri",
        "onboarding.start": "Başla",

        // App Errors
        "error.config.title": "Yapılandırma Hatası",
        "error.config.message": "Uygulama yapılandırması eksik. Lütfen destek ile iletişime geçin.",
        "error.database.title": "Veritabanı Hatası",
        "error.database.message": "Yerel depolama yüklenemedi. Verileriniz oturumlar arasında kaydedilmeyecek. Lütfen uygulamayı yeniden başlatın.",

        // URL Preview Premium Upsell
        "preview.premium.title": "URL Önizleme Premium özelliği",
        "preview.premium.desc": "Tüm yer imleri için otomatik başlık ve resim çıkarma özelliğini aç",
    ]
}
