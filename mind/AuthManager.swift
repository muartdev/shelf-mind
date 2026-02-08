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
    
    // For now, simple local auth
    // Later: Supabase integration
    
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        // Simulate API call
        try? await Task.sleep(for: .seconds(1))
        
        // Simple validation
        guard email.contains("@") else {
            error = "Invalid email address"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            error = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        // Create user
        currentUser = User(
            email: email,
            name: email.components(separatedBy: "@").first ?? "User"
        )
        
        isAuthenticated = true
        isLoading = false
        
        // Save to UserDefaults
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(email, forKey: "userEmail")
    }
    
    func signUp(email: String, name: String, password: String) async {
        isLoading = true
        error = nil
        
        // Simulate API call
        try? await Task.sleep(for: .seconds(1))
        
        // Simple validation
        guard email.contains("@") else {
            error = "Invalid email address"
            isLoading = false
            return
        }
        
        guard !name.isEmpty else {
            error = "Name is required"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            error = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        // Create user
        currentUser = User(email: email, name: name)
        isAuthenticated = true
        isLoading = false
        
        // Save to UserDefaults
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(name, forKey: "userName")
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
    }
    
    func loadCurrentUser() {
        if UserDefaults.standard.bool(forKey: "isAuthenticated") {
            let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
            let name = UserDefaults.standard.string(forKey: "userName") ?? ""
            
            currentUser = User(email: email, name: name)
            isAuthenticated = true
        }
    }
}
