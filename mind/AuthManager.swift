//
//  AuthManager.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class AuthManager {
    var isAuthenticated = false
    var currentUser: User?
    var isLoading = false
    var error: String?
    var needsEmailConfirmation = false
    var pendingEmail: String?
    var infoKey: String?
    
    private let supabase = SupabaseManager.shared
    
    init() {
        setupLanguageSync()
    }
    
    private func setupLanguageSync() {
        LocalizationManager.shared.onLanguageChange = { [weak self] language in
            guard let self = self, let userId = self.currentUser?.id else { return }
            
            Task {
                try? await self.supabase.updateUserProfile(userId: userId, languageCode: language.code)
            }
        }
    }
    
    func signInWithApple(idToken: String, nonce: String, fullName: (givenName: String?, familyName: String?)?) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        infoKey = nil
        needsEmailConfirmation = false
        defer { isLoading = false }
        
        do {
            let user = try await supabase.signInWithApple(idToken: idToken, nonce: nonce, fullName: fullName)
            currentUser = user
            isAuthenticated = true
            saveSession(userId: user.id.uuidString, email: user.email, name: user.name)
            
            PaywallManager.shared.setPremiumFromDatabase(
                isPremium: user.isPremium,
                expirationDate: user.premiumUntil,
                purchaseDate: user.premiumPurchaseDate
            )
            
            if let language = LocalizationManager.AppLanguage.allCases.first(where: { $0.code == user.languageCode }) {
                LocalizationManager.shared.currentLanguage = language
            }
            
            await SupabaseManager.shared.syncPendingOperations()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func signIn(email: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        infoKey = nil
        needsEmailConfirmation = false
        defer { isLoading = false }
        
        do {
            let user = try await supabase.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            saveSession(userId: user.id.uuidString, email: user.email, name: user.name)
            
            // Sync premium status from DB
            PaywallManager.shared.setPremiumFromDatabase(
                isPremium: user.isPremium,
                expirationDate: user.premiumUntil,
                purchaseDate: user.premiumPurchaseDate
            )
            
            // Apply language preference
            if let language = LocalizationManager.AppLanguage.allCases.first(where: { $0.code == user.languageCode }) {
                LocalizationManager.shared.currentLanguage = language
            }
            
            await SupabaseManager.shared.syncPendingOperations()
        } catch {
            let message = error.localizedDescription
            if error is SupabaseManager.ProfileError {
                self.error = "auth.error.profile_missing"
                return
            }
            if message.lowercased().contains("email not confirmed") {
                needsEmailConfirmation = true
                pendingEmail = email
            }
            self.error = message
        }
    }
    
    func signUp(email: String, name: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        infoKey = nil
        needsEmailConfirmation = false
        defer { isLoading = false }
        
        do {
            let result = try await supabase.signUp(email: email, password: password, name: name)
            currentUser = result.user
            pendingEmail = email
            
            if result.session == nil {
                isAuthenticated = false
                needsEmailConfirmation = true
                infoKey = "auth.verify.sent"
                isLoading = false
                return
            }
            
            isAuthenticated = true
            saveSession(userId: result.user.id.uuidString, email: result.user.email, name: result.user.name)
            
            // New user is free by default, but update anyway
            PaywallManager.shared.setPremiumFromDatabase(
                isPremium: result.user.isPremium,
                expirationDate: result.user.premiumUntil,
                purchaseDate: result.user.premiumPurchaseDate
            )
            
            await SupabaseManager.shared.syncPendingOperations()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func signOut() {
        Task {
            try? await supabase.signOut()
        }
        
        currentUser = nil
        isAuthenticated = false
        needsEmailConfirmation = false
        pendingEmail = nil
        infoKey = nil
        clearSession()
    }
    
    func deleteAccount() async {
        guard let userId = currentUser?.id else { return }
        
        isLoading = true
        error = nil
        
        do {
            // 1. Delete user data/profile
            try await supabase.deleteAccount(userId: userId)
            
            // 2. Sign out
            signOut()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func loadCurrentUser() async {
        // Check local session first
        guard UserDefaults.standard.bool(forKey: "isAuthenticated") else { return }
        
        // Try to get current user from Supabase
        do {
            if let user = try await supabase.getCurrentUser() {
                currentUser = user
                isAuthenticated = true
                needsEmailConfirmation = false
                pendingEmail = nil
                infoKey = nil
                saveSession(userId: user.id.uuidString, email: user.email, name: user.name)

                // Sync premium status from DB
                PaywallManager.shared.setPremiumFromDatabase(
                    isPremium: user.isPremium,
                    expirationDate: user.premiumUntil,
                    purchaseDate: user.premiumPurchaseDate
                )
                
                // Apply language preference
                if let language = LocalizationManager.AppLanguage.allCases.first(where: { $0.code == user.languageCode }) {
                    LocalizationManager.shared.currentLanguage = language
                }
                
                await SupabaseManager.shared.syncPendingOperations()
            } else {
                clearSession()
            }
        } catch {
            clearSession()
        }
    }
    
    // MARK: - Session Management
    
    private func saveSession(userId: String, email: String, name: String) {
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(name, forKey: "userName")
        // Sync to app group for Share Extension
        let group = UserDefaults(suiteName: "group.com.muartdev.mind")
        group?.set(true, forKey: "isAuthenticated")
        group?.set(userId, forKey: "userId")
    }
    
    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        // Sync to app group for Share Extension
        let group = UserDefaults(suiteName: "group.com.muartdev.mind")
        group?.removeObject(forKey: "isAuthenticated")
        group?.removeObject(forKey: "userId")
        // Clear pending sync ops so they don't apply to the next user
        supabase.clearPendingOperations()
    }

    func resendConfirmation() async {
        guard let email = pendingEmail else { return }
        isLoading = true
        error = nil
        infoKey = nil
        do {
            try await supabase.resendSignupConfirmation(email: email)
            infoKey = "auth.verify.sent"
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func sendPasswordReset(email: String) async throws {
        try await supabase.sendPasswordReset(email: email)
    }

    func verifyEmailOTP(code: String) async {
        guard let email = pendingEmail else { return }
        isLoading = true
        error = nil
        infoKey = nil
        
        do {
            try await supabase.verifyEmailOTP(email: email, token: code)
            if let user = try await supabase.getCurrentUser() {
                currentUser = user
                isAuthenticated = true
                needsEmailConfirmation = false
                pendingEmail = nil
                saveSession(userId: user.id.uuidString, email: user.email, name: user.name)
                
                PaywallManager.shared.setPremiumFromDatabase(
                    isPremium: user.isPremium,
                    expirationDate: user.premiumUntil,
                    purchaseDate: user.premiumPurchaseDate
                )
                
                if let language = LocalizationManager.AppLanguage.allCases.first(where: { $0.code == user.languageCode }) {
                    LocalizationManager.shared.currentLanguage = language
                }
                
                infoKey = "auth.verify.success"
                await SupabaseManager.shared.syncPendingOperations()
            } else {
                self.error = "Unable to fetch user after verification."
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }

    func cancelEmailVerification() {
        needsEmailConfirmation = false
        pendingEmail = nil
        infoKey = nil
        error = nil
    }
}
