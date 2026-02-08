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
    
    private let supabase = SupabaseManager.shared
    
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let user = try await supabase.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            saveSession(userId: user.id.uuidString, email: user.email, name: user.name)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp(email: String, name: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let user = try await supabase.signUp(email: email, password: password, name: name)
            currentUser = user
            isAuthenticated = true
            saveSession(userId: user.id.uuidString, email: user.email, name: user.name)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        Task {
            try? await supabase.signOut()
        }
        
        currentUser = nil
        isAuthenticated = false
        clearSession()
    }
    
    func loadCurrentUser() async {
        // Check local session first
        guard UserDefaults.standard.bool(forKey: "isAuthenticated") else { return }
        
        // Try to get current user from Supabase
        do {
            if let user = try await supabase.getCurrentUser() {
                currentUser = user
                isAuthenticated = true
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
    }
    
    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
    }
}
