//
//  mindApp.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData

private let appGroupID = "group.com.muartdev.mind"

@main
struct mindApp: App {
    @State private var authManager = AuthManager()
    @State private var themeManager = ThemeManager()
    @State private var localizationManager = LocalizationManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showDatabaseError = false
    @State private var showConfigError = false

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bookmark.self,
            User.self,
        ])

        // Try 1: App Group storage (shared with widget & share extension)
        do {
            let config = ModelConfiguration(
                "MindShelf",
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(appGroupID)
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
        }

        // Try 2: Default storage (no App Group)
        do {
            let config = ModelConfiguration(
                "MindShelfDefault",
                schema: schema,
                isStoredInMemoryOnly: false
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
        }

        // Fallback: in-memory (always succeeds)
        let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [fallbackConfig])
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    // First: Show onboarding
                    OnboardingView()
                } else if authManager.isAuthenticated || authManager.isGuestMode {
                    // Account optional: full local app without sign-in (5.1.1); sign-in adds cloud sync.
                    MainTabView()
                } else {
                    // Otherwise: Show auth screen
                    AuthView()
                }
            }
            .environment(authManager)
            .environment(themeManager)
            .environment(localizationManager)
            .environment(SupabaseManager.shared)
            .preferredColorScheme(themeManager.currentTheme.isDark ? .dark : .light)
            .tint(themeManager.currentTheme.accentColor)
            .task {
                if authManager.isGuestMode {
                    // Guest uses local SwiftData only; Supabase optional until sign-in
                    if sharedModelContainer.configurations.first?.isStoredInMemoryOnly == true {
                        showDatabaseError = true
                    }
                    return
                }
                if !SupabaseManager.shared.isConfigured {
                    showConfigError = true
                    return
                }
                await authManager.loadCurrentUser()
                // Warn if running on fallback in-memory store
                if sharedModelContainer.configurations.first?.isStoredInMemoryOnly == true {
                    showDatabaseError = true
                }
            }
            .alert(LocalizationManager.shared.localizedString("error.config.title"), isPresented: $showConfigError) {
                Button(LocalizationManager.shared.localizedString("common.done"), role: .cancel) {}
            } message: {
                Text(LocalizationManager.shared.localizedString("error.config.message"))
            }
            .alert(LocalizationManager.shared.localizedString("error.database.title"), isPresented: $showDatabaseError) {
                Button(LocalizationManager.shared.localizedString("common.done"), role: .cancel) {}
            } message: {
                Text(LocalizationManager.shared.localizedString("error.database.message"))
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
