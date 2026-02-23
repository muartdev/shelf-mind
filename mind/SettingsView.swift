//
//  SettingsView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData
import StoreKit
import UserNotifications

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    @Environment(\.modelContext) private var modelContext
    @Environment(SupabaseManager.self) private var supabaseManager
    @Query private var bookmarks: [Bookmark]
    
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var reminderTime = {
        if let saved = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
            return saved
        }
        // Default to 9:00 AM
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    @State private var showingPaywall = false
    @State private var showingPaywallForTheme = false
    @State private var showingPremiumDetails = false

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        premiumSection
                        profileSection
                        appearanceSection
                        notificationsSection
                        dataManagementSection
                        aboutSection
                        signOutSection
                    }
                    .padding()
                }
            }
            .navigationTitle(localization.localizedString("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPaywallForTheme) {
                PaywallView()
            }
            .confirmationDialog(localization.localizedString("settings.delete.all"), isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button(localization.localizedString("settings.delete.all.confirm"), role: .destructive) {
                    deleteAllBookmarks()
                }
                Button(localization.localizedString("common.cancel"), role: .cancel) { }
            } message: {
                Text(localization.localizedString("settings.delete.all.message"))
            }
.confirmationDialog(localization.localizedString("settings.delete.account"), isPresented: $showingDeleteAccountConfirmation, titleVisibility: .visible) {
                Button(localization.localizedString("settings.delete.confirm"), role: .destructive) {
                    deleteAccount()
                }
                Button(localization.localizedString("common.cancel"), role: .cancel) { }
            } message: {
                Text(localization.localizedString("settings.delete.account.message"))
            }
        }
    }

    // MARK: - Profile Section

    @ViewBuilder
    private var profileSection: some View {
        if let user = authManager.currentUser {
            HStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(
                        colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Text(user.name.prefix(1).uppercased())
                            .font(.title)
                            .foregroundStyle(.primary)
                    }
                    .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .settingsCardStyle()
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localizedString("settings.appearance"))
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: themeManager.currentTheme == theme,
                        action: {
                            if !PaywallManager.shared.isPremium {
                                showingPaywallForTheme = true
                            } else {
                                withAnimation(.smooth) {
                                    themeManager.currentTheme = theme
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .settingsCardStyle()
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.localizedString("settings.notifications"))
                .font(.headline)
                .foregroundStyle(.secondary)

            Toggle(localization.localizedString("settings.enable.notifications"), isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")
                    if newValue {
                        requestNotificationPermission()
                    } else {
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                    syncNotificationSettingsToSupabase()
                }

            if notificationsEnabled {
                DatePicker(localization.localizedString("settings.daily.reminder"), selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "reminderTime")
                        scheduleDailyReminder()
                        syncNotificationSettingsToSupabase()
                    }
            }
        }
        .padding()
        .settingsCardStyle()
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.localizedString("settings.about"))
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack {
                Label(localization.localizedString("settings.language"), systemImage: "globe")
                Spacer()
                Picker("", selection: Binding(
                    get: { localization.currentLanguage },
                    set: { newLang in
                        withAnimation(.smooth) {
                            LocalizationManager.shared.currentLanguage = newLang
                        }
                    }
                )) {
                    ForEach(LocalizationManager.AppLanguage.allCases) { language in
                        Text("\(language.flag) \(language.rawValue)").tag(language)
                    }
                }
                .pickerStyle(.menu)
                .tint(.secondary)
            }

            Divider()

            HStack {
                Text(localization.localizedString("settings.version"))
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Link(destination: URL(string: "https://muartdev.github.io/mindshelf-privacy/")!) {
                HStack {
                    Label(localization.localizedString("settings.privacy.policy"), systemImage: "hand.raised.fill")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Link(destination: URL(string: "https://muartdev.github.io/mindshelf-privacy/")!) {
                HStack {
                    Label(localization.localizedString("settings.terms"), systemImage: "doc.text.fill")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .settingsCardStyle()
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        VStack(spacing: 12) {
            Button(role: .destructive, action: signOut) {
                Text(localization.localizedString("settings.signout"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .settingsCardStyle()

            Button(role: .destructive, action: { showingDeleteAccountConfirmation = true }) {
                Text(localization.localizedString("settings.delete.account"))
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
    
    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        VStack(spacing: 0) {
            Text(localization.localizedString("settings.data"))
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    HStack {
                        Label(localization.localizedString("settings.delete.all"), systemImage: "trash")
                        Spacer()
                    }
                    .padding()
                }
            }
            .settingsCardStyle()
        }
    }

    // MARK: - Premium Section
    
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if PaywallManager.shared.isPremium {
                // Premium Badge & Info
                Button(action: { showingPremiumDetails = true }) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                            Text(localization.localizedString("settings.premium.active"))
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // ... rest of the existing premium info ...
                        if PaywallManager.shared.premiumPurchaseDate != nil || PaywallManager.shared.premiumExpirationDate != nil {
                            Divider()
                                .background(.primary.opacity(0.1))
                            
                            VStack(spacing: 8) {
                                if let purchaseDate = PaywallManager.shared.premiumPurchaseDate {
                                    HStack {
                                        Text(localization.localizedString("settings.member.since"))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(purchaseDate.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: localization.currentLanguage.code))))
                                            .fontWeight(.medium)
                                    }
                                }
                                
                                if PaywallManager.shared.isLifetime {
                                    HStack {
                                        Text(localization.localizedString("settings.renews.on"))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(localization.localizedString("premium.lifetime"))
                                            .fontWeight(.medium)
                                            .foregroundStyle(.yellow)
                                    }
                                } else if let expirationDate = PaywallManager.shared.premiumExpirationDate {
                                    HStack {
                                        Text(localization.localizedString("settings.renews.on"))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(expirationDate.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: localization.currentLanguage.code))))
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.yellow.opacity(0.2), .orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.yellow.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingPremiumDetails) {
                    premiumDetailView
                }
            } else {
                // Upgrade CTA
                // ... same as before ...
                Button(action: { showingPaywall = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.yellow)
                                Text(localization.localizedString("settings.upgrade"))
                                    .font(.headline)
                            }
                            
                            Text(localization.localizedString("settings.premium.desc"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("\(localization.localizedString("settings.premium.from")) $2.99/month")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .settingsCardStyle()
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private var premiumDetailView: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.gradientColors[0].opacity(0.1).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.yellow)
                                .shadow(radius: 10)
                            
                            Text(localization.localizedString("settings.premium.active"))
                                .font(.title)
                                .bold()
                        }
                        .padding(.top, 40)
                        
                        // Benefits List
                        VStack(alignment: .leading, spacing: 20) {
                            Text(localization.localizedString("settings.premium.benefits"))
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 1) {
                                BenefitRow(icon: "infinity", title: localization.localizedString("feature.unlimited"), desc: localization.localizedString("feature.unlimited.desc"))
                                Divider().padding(.leading, 56)
                                BenefitRow(icon: "link.badge.plus", title: localization.localizedString("feature.preview"), desc: localization.localizedString("feature.preview.desc"))
                                Divider().padding(.leading, 56)
                                BenefitRow(icon: "chart.bar.fill", title: localization.localizedString("feature.stats"), desc: localization.localizedString("feature.stats.desc"))
                                Divider().padding(.leading, 56)
                                BenefitRow(icon: "paintbrush.fill", title: localization.localizedString("feature.themes"), desc: localization.localizedString("feature.themes.desc"))
                            }
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal)
                        
                        if !PaywallManager.shared.isLifetime {
                            // Subscription Info
                            VStack(alignment: .leading, spacing: 20) {
                                Text(localization.localizedString("settings.account"))
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 16) {
                                    // Status & Expiration
                                    if let expirationDate = PaywallManager.shared.premiumExpirationDate {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(localization.localizedString("settings.renews.on"))
                                                    .foregroundStyle(.secondary)
                                                Spacer()
                                                Text(expirationDate.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: localization.currentLanguage.code))))
                                                    .fontWeight(.medium)
                                            }
                                            
                                            Text(localization.localizedString("settings.premium.expiration.desc"))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                        .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                                    }
                                    
                                    // Cancellation Guide
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "questionmark.circle.fill")
                                                .foregroundStyle(.blue)
                                            Text(localization.localizedString("settings.premium.cancellation.title"))
                                                .fontWeight(.medium)
                                        }
                                        
                                        Text(localization.localizedString("settings.premium.cancellation.desc"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Button(action: openSubscriptionManagement) {
                                            HStack {
                                                Text(localization.localizedString("settings.premium.manage"))
                                                    .fontWeight(.semibold)
                                                Image(systemName: "arrow.up.right")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(themeManager.currentTheme.primaryColor, in: RoundedRectangle(cornerRadius: 12))
                                            .foregroundStyle(.white)
                                        }
                                    }
                                    .padding()
                                    .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(localization.localizedString("settings.premium"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.localizedString("common.done")) {
                        showingPremiumDetails = false
                    }
                }
            }
        }
    }
    
    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    private func signOut() {
        clearLocalBookmarksOnly()
        authManager.signOut()
    }
    
    /// Clears all bookmarks from local SwiftData (used on sign out so next user sees only their data)
    private func clearLocalBookmarksOnly() {
        let descriptor = FetchDescriptor<Bookmark>()
        let allBookmarks = (try? modelContext.fetch(descriptor)) ?? []
        for bookmark in allBookmarks {
            modelContext.delete(bookmark)
        }
        try? modelContext.save()
    }
    
    private func deleteAllBookmarks() {
        let idsToDelete = bookmarks.map(\.id)
        for bookmark in bookmarks {
            modelContext.delete(bookmark)
        }
        try? modelContext.save()

        // Sync deletion to Supabase
        if authManager.currentUser != nil {
            Task {
                for id in idsToDelete {
                    try? await supabaseManager.deleteBookmark(id: id)
                }
            }
        }
    }
    
    private func syncNotificationSettingsToSupabase() {
        guard let userId = authManager.currentUser?.id else { return }
        Task {
            try? await supabaseManager.updateUserProfile(
                userId: userId,
                notificationsEnabled: notificationsEnabled,
                reminderTime: reminderTime
            )
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    scheduleDailyReminder()
                } else {
                    notificationsEnabled = false
                    UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                }
            }
        }
    }

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])

        let content = UNMutableNotificationContent()
        content.title = "MindShelf"
        content.body = localization.localizedString("notification.daily.body")
        content.sound = .default

        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: reminderTime)
        dateComponents.minute = calendar.component(.minute, from: reminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)

        center.add(request)
    }


    private func deleteAccount() {
        Task {
            // 1. Clear local bookmarks if needed (though sign out clears access)
            deleteAllBookmarks()
            
            // 2. Perform account deletion
            await authManager.deleteAccount()
        }
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    @Environment(LocalizationManager.self) private var localization
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Theme preview circle
                ZStack {
                    Circle()
                        .fill(theme.previewGradient)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: theme.icon)
                        .font(.body)
                        .foregroundStyle(.white)

                    if isSelected {
                        Circle()
                            .strokeBorder(theme.primaryColor, lineWidth: 2.5)
                            .frame(width: 54, height: 54)
                    }
                }
                
                VStack(spacing: 1) {
                    Text(theme.displayName)
                        .font(.caption2)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(localization.localizedString(theme.isDark ? "theme.dark" : "theme.light"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Card Style

extension View {
    func settingsCardStyle() -> some View {
        self
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .primary.opacity(0.1), radius: 15, x: 0, y: 8)
            .shadow(color: .primary.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    let authManager = AuthManager()
    authManager.currentUser = User.sample
    authManager.isAuthenticated = true
    
    return SettingsView()
        .environment(authManager)
        .environment(ThemeManager())
}

// MARK: - Premium Benefit Row

struct BenefitRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.yellow.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(.yellow)
                    .font(.subheadline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}
