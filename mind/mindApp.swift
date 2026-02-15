//
//  mindApp.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData

@main
struct mindApp: App {
    @State private var authManager = AuthManager()
    @State private var themeManager = ThemeManager()
    @State private var localizationManager = LocalizationManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showDatabaseError = false

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bookmark.self,
            User.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            #if DEBUG
            print("❌ Failed to create ModelContainer: \(error). Falling back to in-memory store.")
            #endif
            // Fallback: in-memory container so the app doesn't crash
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Could not create even in-memory ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    // First: Show onboarding
                    OnboardingView()
                } else if authManager.isAuthenticated {
                    // Then: If logged in, show main app
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
                await authManager.loadCurrentUser()
                // Warn if running on fallback in-memory store
                if sharedModelContainer.configurations.first?.isStoredInMemoryOnly == true {
                    showDatabaseError = true
                }
            }
            .alert("Database Error", isPresented: $showDatabaseError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Local storage could not be loaded. Your data will not be saved between sessions. Please restart the app.")
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
