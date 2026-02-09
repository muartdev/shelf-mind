//
//  SettingsView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [Bookmark]
    
    @State private var notificationsEnabled = true
    @State private var reminderTime = Date()
    @State private var showingDeleteConfirmation = false
    @State private var showingPaywall = false
    @State private var showingPaywallForTheme = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Premium Section
                        premiumSection
                        
                        // Profile Section
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
                                            .foregroundStyle(.white)
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
                        
                        // Appearance Section
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
                                            // All theme changes require premium
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
                        
                        // Notifications
                        VStack(alignment: .leading, spacing: 16) {
                            Text(localization.localizedString("settings.notifications"))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Toggle(localization.localizedString("settings.enable.notifications"), isOn: $notificationsEnabled)
                            
                            if notificationsEnabled {
                                DatePicker(localization.localizedString("settings.daily.reminder"), selection: $reminderTime, displayedComponents: .hourAndMinute)
                            }
                        }
                        .padding()
                        .settingsCardStyle()
                        
                        // Language Section (moved here)
                        languageSection
                        
                        // Data Management
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
                        
                        // About
                        VStack(alignment: .leading, spacing: 16) {
                            Text(localization.localizedString("settings.about"))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Text(localization.localizedString("settings.version"))
                                Spacer()
                                Text("1.0.0")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .settingsCardStyle()
                        
                        // Sign Out
                        Button(role: .destructive, action: signOut) {
                            Text(localization.localizedString("settings.signout"))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .settingsCardStyle()
                    }
                    .padding()
                }
            }
            .navigationTitle(localization.localizedString("settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPaywallForTheme) {
                PaywallView()
            }
            .confirmationDialog("Delete All Bookmarks", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    deleteAllBookmarks()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All your bookmarks will be permanently deleted.")
            }
        }
    }
    
    // MARK: - Premium Section
    
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localizedString("settings.language"))
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ForEach(LocalizationManager.AppLanguage.allCases) { language in
                    Button(action: {
                        withAnimation(.smooth) {
                            LocalizationManager.shared.currentLanguage = language
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(language.flag)
                                .font(.title2)
                            Text(language.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LocalizationManager.shared.currentLanguage == language
                                ? .ultraThinMaterial
                                : .thinMaterial,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    LocalizationManager.shared.currentLanguage == language
                                        ? themeManager.currentTheme.primaryColor
                                        : .white.opacity(0.2),
                                    lineWidth: LocalizationManager.shared.currentLanguage == language ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .settingsCardStyle()
    }
    
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if PaywallManager.shared.isPremium {
                // Premium Badge & Info
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text(localization.localizedString("settings.premium.active"))
                            .font(.headline)
                        Spacer()
                        Text("✓")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                    
                    if PaywallManager.shared.premiumPurchaseDate != nil || PaywallManager.shared.premiumExpirationDate != nil {
                        Divider()
                            .background(.white.opacity(0.2))
                        
                        VStack(spacing: 8) {
                            if let purchaseDate = PaywallManager.shared.premiumPurchaseDate {
                                HStack {
                                    Text("Member Since")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(purchaseDate.formatted(date: .abbreviated, time: .omitted))
                                        .fontWeight(.medium)
                                }
                            }
                            
                            if let expirationDate = PaywallManager.shared.premiumExpirationDate {
                                HStack {
                                    Text("Renews/Expires")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(expirationDate.formatted(date: .abbreviated, time: .omitted))
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
            } else {
                // Upgrade CTA
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
    
    private func signOut() {
        authManager.signOut()
    }
    
    private func deleteAllBookmarks() {
        for bookmark in bookmarks {
            modelContext.delete(bookmark)
        }
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
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
                    Text(theme.isDark ? "Dark" : "Light")
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
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
