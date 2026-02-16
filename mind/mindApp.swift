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

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bookmark.self,
            User.self,
        ])

        // Prefer App Group storage for reliable access on device
        let storeURL: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            .map { $0.appending(path: "Library/Application Support/default.store") }

        func ensureStoreDirectoryExists() {
            guard let url = storeURL else { return }
            let dir = url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        func deleteStoreFiles(at url: URL) {
            let fm = FileManager.default
            try? fm.removeItem(at: url)
            try? fm.removeItem(atPath: url.path + "-shm")
            try? fm.removeItem(atPath: url.path + "-wal")
        }

        // Try 1: App Group storage (most reliable on device)
        if let url = storeURL {
            ensureStoreDirectoryExists()
            let config = ModelConfiguration(schema: schema, url: url, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                #if DEBUG
                print("❌ ModelContainer (App Group) failed: \(error). Retrying after store reset...")
                #endif
                deleteStoreFiles(at: url)
                ensureStoreDirectoryExists()
                do {
                    return try ModelContainer(for: schema, configurations: [config])
                } catch {
                    #if DEBUG
                    print("❌ Retry failed: \(error). Trying default location...")
                #endif
                }
            }
        }

        // Try 2: Default Application Support
        let defaultDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let defaultURL = defaultDir.appending(path: "default.store")
        try? FileManager.default.createDirectory(at: defaultDir, withIntermediateDirectories: true)
        let defaultConfig = ModelConfiguration(schema: schema, url: defaultURL, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [defaultConfig])
        } catch {
            #if DEBUG
            print("❌ Default store failed: \(error). Retrying after reset...")
            #endif
            deleteStoreFiles(at: defaultURL)
            do {
                return try ModelContainer(for: schema, configurations: [defaultConfig])
            } catch {
                #if DEBUG
                print("❌ Retry failed: \(error). Falling back to in-memory.")
                #endif
            }
        }

        // Fallback: in-memory
        let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [fallbackConfig])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
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
