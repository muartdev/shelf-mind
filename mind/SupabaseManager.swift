//
//  SupabaseManager.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import Foundation
// import Supabase // Will be added via SPM

@Observable
@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    // Supabase credentials - REPLACE WITH YOUR CREDENTIALS
    private let supabaseURL = "YOUR_SUPABASE_URL" // e.g., https://xxxxx.supabase.co
    private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
    
    // var client: SupabaseClient // Will be initialized when package is added
    
    private init() {
        // Initialize Supabase client
        // self.client = SupabaseClient(supabaseURL: URL(string: supabaseURL)!, supabaseKey: supabaseKey)
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        // TODO: Implement Supabase sign up
        // let authResponse = try await client.auth.signUp(email: email, password: password)
        
        // Create user profile
        // let user = User(id: authResponse.user.id, email: email, name: name)
        // try await client.from("users").insert(user).execute()
        
        // Return demo user for now
        return User(email: email, name: name)
    }
    
    func signIn(email: String, password: String) async throws -> User {
        // TODO: Implement Supabase sign in
        // let authResponse = try await client.auth.signIn(email: email, password: password)
        
        // Fetch user profile
        // let response = try await client.from("users")
        //     .select()
        //     .eq("id", value: authResponse.user.id)
        //     .single()
        //     .execute()
        
        // Return demo user for now
        return User(email: email, name: "Demo User")
    }
    
    func signOut() async throws {
        // TODO: Implement Supabase sign out
        // try await client.auth.signOut()
    }
    
    func getCurrentUser() async throws -> User? {
        // TODO: Get current authenticated user
        // guard let session = client.auth.session else { return nil }
        
        // let response = try await client.from("users")
        //     .select()
        //     .eq("id", value: session.user.id)
        //     .single()
        //     .execute()
        
        return nil
    }
    
    // MARK: - Bookmarks
    
    func fetchBookmarks(userId: String) async throws -> [Bookmark] {
        // TODO: Fetch bookmarks from Supabase
        // let response = try await client.from("bookmarks")
        //     .select()
        //     .eq("user_id", value: userId)
        //     .order("created_at", ascending: false)
        //     .execute()
        
        return []
    }
    
    func createBookmark(_ bookmark: Bookmark, userId: String) async throws {
        // TODO: Create bookmark in Supabase
        // try await client.from("bookmarks").insert(bookmark).execute()
    }
    
    func updateBookmark(_ bookmark: Bookmark) async throws {
        // TODO: Update bookmark in Supabase
        // try await client.from("bookmarks")
        //     .update(bookmark)
        //     .eq("id", value: bookmark.id)
        //     .execute()
    }
    
    func deleteBookmark(id: UUID) async throws {
        // TODO: Delete bookmark from Supabase
        // try await client.from("bookmarks")
        //     .delete()
        //     .eq("id", value: id)
        //     .execute()
    }
}
