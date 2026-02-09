//
//  SupabaseManager.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import Foundation
import Supabase
import Auth

@Observable
@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Initialize Supabase client with config
        print("🔍 DEBUG: supabaseURL = \(Config.supabaseURL)")
        print("🔍 DEBUG: supabaseURL.host = \(Config.supabaseURL.host ?? "nil")")
        print("🔍 DEBUG: supabaseKey = \(Config.supabaseAnonKey.prefix(20))...")
        
        self.client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name)]
        )
        
        // User profile is auto-created by database trigger
        let user = User(
            id: authResponse.user.id,
            email: email,
            name: name
        )
        
        return user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let authResponse = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        // Fetch user profile
        let response: UserProfile = try await client.from("users")
            .select()
            .eq("id", value: authResponse.user.id.uuidString)
            .single()
            .execute()
            .value
        
        let user = User(
            id: response.id,
            email: response.email,
            name: response.name,
            avatarURL: response.avatar_url,
            createdAt: response.created_at
        )
        
        return user
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentUser() async throws -> User? {
        // Try to get current session
        let session: Session
        do {
            session = try await client.auth.session
        } catch {
            // No active session
            return nil
        }
        
        let response: UserProfile = try await client.from("users")
            .select()
            .eq("id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value
        
        let user = User(
            id: response.id,
            email: response.email,
            name: response.name,
            avatarURL: response.avatar_url,
            createdAt: response.created_at
        )
        
        return user
    }
    
    // MARK: - Bookmarks
    
    func fetchBookmarks(userId: UUID) async throws -> [BookmarkDTO] {
        let response: [BookmarkDTO] = try await client.from("bookmarks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func createBookmark(_ bookmark: Bookmark, userId: UUID) async throws {
        let dto = BookmarkDTO(
            id: bookmark.id,
            user_id: userId,
            title: bookmark.title,
            url: bookmark.url,
            notes: bookmark.notes,
            category: bookmark.category,
            tags: bookmark.tags,
            is_read: bookmark.isRead,
            thumbnail_url: bookmark.thumbnailURL
        )
        
        try await client.from("bookmarks")
            .insert(dto)
            .execute()
    }
    
    func updateBookmark(_ bookmark: Bookmark) async throws {
        let dto = BookmarkDTO(
            id: bookmark.id,
            user_id: nil, // Not needed for update
            title: bookmark.title,
            url: bookmark.url,
            notes: bookmark.notes,
            category: bookmark.category,
            tags: bookmark.tags,
            is_read: bookmark.isRead,
            thumbnail_url: bookmark.thumbnailURL
        )
        
        try await client.from("bookmarks")
            .update(dto)
            .eq("id", value: bookmark.id.uuidString)
            .execute()
    }
    
    func deleteBookmark(id: UUID) async throws {
        try await client.from("bookmarks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - DTOs (Data Transfer Objects)

struct UserProfile: Codable {
    let id: UUID
    let email: String
    let name: String
    let avatar_url: String?
    let created_at: Date
}

struct BookmarkDTO: Codable {
    let id: UUID
    let user_id: UUID?
    let title: String
    let url: String
    let notes: String
    let category: String
    let tags: [String]
    let is_read: Bool
    let thumbnail_url: String?
    let created_at: Date?
    let updated_at: Date?
    
    init(id: UUID, user_id: UUID?, title: String, url: String, notes: String, category: String, tags: [String], is_read: Bool, thumbnail_url: String?, created_at: Date? = nil, updated_at: Date? = nil) {
        self.id = id
        self.user_id = user_id
        self.title = title
        self.url = url
        self.notes = notes
        self.category = category
        self.tags = tags
        self.is_read = is_read
        self.thumbnail_url = thumbnail_url
        self.created_at = created_at
        self.updated_at = updated_at
    }
}
