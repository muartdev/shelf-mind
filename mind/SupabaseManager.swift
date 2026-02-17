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
    private let pendingOpsKey = "pendingBookmarkOps"
    var lastSyncError: String?
    
    private init() {
        guard let url = Config.supabaseURL, let key = Config.supabaseAnonKey else {
            fatalError("Supabase configuration missing. Ensure Config.xcconfig is properly linked in Build Settings.")
        }
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
    
    // MARK: - Authentication

    enum ProfileError: Error {
        case missing
    }
    
    struct SignUpResult {
        let user: User
        let session: Session?
    }
    
    func signUp(email: String, password: String, name: String) async throws -> SignUpResult {
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
        
        return SignUpResult(user: user, session: authResponse.session)
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let authResponse = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        // Fetch user profile
        let response = try await fetchOrCreateUserProfile(
            userId: authResponse.user.id,
            email: authResponse.user.email ?? email,
            fallbackName: authResponse.user.email?.split(separator: "@").first.map(String.init) ?? "User"
        )
        
        let user = User(
            id: response.id,
            email: response.email,
            name: response.name,
            avatarURL: response.avatar_url,
            createdAt: response.created_at,
            isPremium: response.is_premium ?? false,
            premiumUntil: response.premium_until,
            premiumPurchaseDate: response.premium_purchase_date,
            languageCode: response.language_code ?? "en"
        )
        
        return user
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resendSignupConfirmation(email: String) async throws {
        try await client.auth.resend(email: email, type: .signup)
    }

    func verifyEmailOTP(email: String, token: String) async throws {
        try await client.auth.verifyOTP(
            email: email,
            token: token,
            type: .signup
        )
    }

    func sendPasswordReset(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
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
        
        let email = session.user.email ?? ""
        let response = try await fetchOrCreateUserProfile(
            userId: session.user.id,
            email: email,
            fallbackName: email.split(separator: "@").first.map(String.init) ?? "User"
        )
        
        let user = User(
            id: response.id,
            email: response.email,
            name: response.name,
            avatarURL: response.avatar_url,
            createdAt: response.created_at,
            isPremium: response.is_premium ?? false,
            premiumUntil: response.premium_until,
            premiumPurchaseDate: response.premium_purchase_date,
            languageCode: response.language_code ?? "en"
        )
        
        return user
    }

    private func fetchOrCreateUserProfile(userId: UUID, email: String, fallbackName: String) async throws -> UserProfile {
        let profiles: [UserProfile] = try await client.from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        
        if let profile = profiles.first {
            return profile
        }
        
        // Try to create profile if missing (requires insert policy)
        struct UserProfileInsert: Encodable {
            let id: UUID
            let email: String
            let name: String
        }
        
        let insert = UserProfileInsert(
            id: userId,
            email: email,
            name: fallbackName
        )
        
        do {
            try await client.from("users")
                .insert(insert)
                .execute()
        } catch {
            throw ProfileError.missing
        }
        
        let retry: [UserProfile] = try await client.from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        
        if let profile = retry.first {
            return profile
        }
        
        throw ProfileError.missing
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
            is_favorite: bookmark.isFavorite,
            thumbnail_url: bookmark.thumbnailURL
        )
        
        guard (try? await client.auth.session) != nil else {
            enqueuePendingOperation(.init(type: .create, bookmark: dto))
            return
        }
        
        do {
            try await client.from("bookmarks")
                .insert(dto)
                .execute()
        } catch {
            enqueuePendingOperation(.init(type: .create, bookmark: dto))
            throw error
        }
    }
    
    func updateBookmark(_ bookmark: Bookmark) async throws {
        // Use BookmarkUpdateDTO to exclude user_id - NOT NULL column must not be set to null
        let dto = BookmarkUpdateDTO(
            title: bookmark.title,
            url: bookmark.url,
            notes: bookmark.notes,
            category: bookmark.category,
            tags: bookmark.tags,
            is_read: bookmark.isRead,
            is_favorite: bookmark.isFavorite,
            thumbnail_url: bookmark.thumbnailURL
        )
        
        guard (try? await client.auth.session) != nil else {
            let fullDto = BookmarkDTO(
                id: bookmark.id,
                user_id: nil,
                title: bookmark.title,
                url: bookmark.url,
                notes: bookmark.notes,
                category: bookmark.category,
                tags: bookmark.tags,
                is_read: bookmark.isRead,
                is_favorite: bookmark.isFavorite,
                thumbnail_url: bookmark.thumbnailURL
            )
            enqueuePendingOperation(.init(type: .update, bookmark: fullDto))
            return
        }
        
        do {
            try await client.from("bookmarks")
                .update(dto)
                .eq("id", value: bookmark.id.uuidString)
                .execute()
        } catch {
            let fullDto = BookmarkDTO(
                id: bookmark.id,
                user_id: nil,
                title: bookmark.title,
                url: bookmark.url,
                notes: bookmark.notes,
                category: bookmark.category,
                tags: bookmark.tags,
                is_read: bookmark.isRead,
                is_favorite: bookmark.isFavorite,
                thumbnail_url: bookmark.thumbnailURL
            )
            enqueuePendingOperation(.init(type: .update, bookmark: fullDto))
            throw error
        }
    }
    
    func deleteBookmark(id: UUID) async throws {
        guard (try? await client.auth.session) != nil else {
            enqueuePendingOperation(.init(type: .delete, bookmark: nil, id: id))
            return
        }
        
        do {
            try await client.from("bookmarks")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            enqueuePendingOperation(.init(type: .delete, bookmark: nil, id: id))
            throw error
        }
    }
    
    // MARK: - Account Management
    
    func deleteAccount(userId: UUID) async throws {
        // Call the SECURITY DEFINER RPC that deletes profile, bookmarks (cascade), and auth record
        try await client.rpc("delete_own_account").execute()
    }
    
    struct PremiumUpdate: Encodable {
        let is_premium: Bool?
        let premium_until: Date?
        let premium_purchase_date: Date?
        let language_code: String?
        let notifications_enabled: Bool?
        let reminder_time: String?

        enum CodingKeys: String, CodingKey {
            case is_premium
            case premium_until
            case premium_purchase_date
            case language_code
            case notifications_enabled
            case reminder_time
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if let is_premium {
                try container.encode(is_premium, forKey: .is_premium)
            }
            if let premium_until {
                try container.encode(premium_until, forKey: .premium_until)
            }
            if let premium_purchase_date {
                try container.encode(premium_purchase_date, forKey: .premium_purchase_date)
            }
            if let language_code {
                try container.encode(language_code, forKey: .language_code)
            }
            if let notifications_enabled {
                try container.encode(notifications_enabled, forKey: .notifications_enabled)
            }
            if let reminder_time {
                try container.encode(reminder_time, forKey: .reminder_time)
            }
        }
    }
    
    func updateUserProfile(userId: UUID, isPremium: Bool? = nil, expirationDate: Date? = nil, purchaseDate: Date? = nil, languageCode: String? = nil, notificationsEnabled: Bool? = nil, reminderTime: Date? = nil) async throws {
        let reminderTimeString: String? = reminderTime.map { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: date)
        }
        let update = PremiumUpdate(
            is_premium: isPremium,
            premium_until: expirationDate,
            premium_purchase_date: purchaseDate,
            language_code: languageCode,
            notifications_enabled: notificationsEnabled,
            reminder_time: reminderTimeString
        )
        
        // Since we want to support partial updates, we might need a more flexible approach if Supabase Encodable doesn't skip nil.
        // For now, following existing pattern.
        
        try await client.from("users")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Pending Operations (Offline Queue)
    
    func syncPendingOperations() async {
        guard let session = try? await client.auth.session else { return }
        
        let pending = loadPendingOperations()
        guard !pending.isEmpty else { return }
        
        var remaining: [PendingBookmarkOperation] = []
        
        for op in pending {
            do {
                switch op.type {
                case .create:
                    guard var dto = op.bookmark else { continue }
                    if dto.user_id == nil {
                        dto.user_id = session.user.id
                    }
                    try await client.from("bookmarks")
                        .insert(dto)
                        .execute()
                    
                case .update:
                    guard let dto = op.bookmark else { continue }
                    let updateDto = BookmarkUpdateDTO(
                        title: dto.title,
                        url: dto.url,
                        notes: dto.notes,
                        category: dto.category,
                        tags: dto.tags,
                        is_read: dto.is_read,
                        is_favorite: dto.is_favorite,
                        thumbnail_url: dto.thumbnail_url
                    )
                    try await client.from("bookmarks")
                        .update(updateDto)
                        .eq("id", value: dto.id.uuidString)
                        .execute()
                    
                case .delete:
                    try await client.from("bookmarks")
                        .delete()
                        .eq("id", value: op.id.uuidString)
                        .execute()
                }
            } catch {
                remaining.append(op)
            }
        }
        
        savePendingOperations(remaining)
    }
    
    private func enqueuePendingOperation(_ op: PendingBookmarkOperation) {
        var ops = loadPendingOperations()
        
        switch op.type {
        case .delete:
            ops.removeAll { $0.id == op.id }
            ops.append(op)
        case .update:
            ops.removeAll { $0.id == op.id && $0.type == .update }
            ops.append(op)
        case .create:
            ops.append(op)
        }
        
        savePendingOperations(ops)
    }
    
    private func loadPendingOperations() -> [PendingBookmarkOperation] {
        guard let data = UserDefaults.standard.data(forKey: pendingOpsKey) else { return [] }
        return (try? JSONDecoder().decode([PendingBookmarkOperation].self, from: data)) ?? []
    }
    
    private func savePendingOperations(_ ops: [PendingBookmarkOperation]) {
        let data = try? JSONEncoder().encode(ops)
        UserDefaults.standard.set(data, forKey: pendingOpsKey)
    }
    
    /// Clears pending operations (call on sign out so they don't sync to the next user)
    func clearPendingOperations() {
        savePendingOperations([])
    }
}

// MARK: - DTOs (Data Transfer Objects)

struct UserProfile: Codable {
    let id: UUID
    let email: String
    let name: String
    let avatar_url: String?
    let created_at: Date
    let is_premium: Bool?
    let premium_until: Date?
    let premium_purchase_date: Date?
    let language_code: String?
}

/// DTO for bookmark updates - excludes user_id and id to avoid NOT NULL violation
struct BookmarkUpdateDTO: Codable {
    var title: String
    var url: String
    var notes: String
    var category: String
    var tags: [String]
    var is_read: Bool
    var is_favorite: Bool
    var thumbnail_url: String?
}

struct BookmarkDTO: Codable {
    enum CodingKeys: String, CodingKey {
        case id, user_id, title, url, notes, category, tags, is_read, is_favorite, thumbnail_url, created_at, updated_at
    }
    var id: UUID
    var user_id: UUID?
    var title: String
    var url: String
    var notes: String
    var category: String
    var tags: [String]
    var is_read: Bool
    var is_favorite: Bool
    var thumbnail_url: String?
    var created_at: Date?
    var updated_at: Date?
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        user_id = try c.decodeIfPresent(UUID.self, forKey: .user_id)
        title = try c.decode(String.self, forKey: .title)
        url = try c.decode(String.self, forKey: .url)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        category = try c.decode(String.self, forKey: .category)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        is_read = try c.decodeIfPresent(Bool.self, forKey: .is_read) ?? false
        is_favorite = try c.decodeIfPresent(Bool.self, forKey: .is_favorite) ?? false
        thumbnail_url = try c.decodeIfPresent(String.self, forKey: .thumbnail_url)
        created_at = try c.decodeIfPresent(Date.self, forKey: .created_at)
        updated_at = try c.decodeIfPresent(Date.self, forKey: .updated_at)
    }
    
    init(id: UUID, user_id: UUID?, title: String, url: String, notes: String, category: String, tags: [String], is_read: Bool, is_favorite: Bool = false, thumbnail_url: String?, created_at: Date? = nil, updated_at: Date? = nil) {
        self.id = id
        self.user_id = user_id
        self.title = title
        self.url = url
        self.notes = notes
        self.category = category
        self.tags = tags
        self.is_read = is_read
        self.is_favorite = is_favorite
        self.thumbnail_url = thumbnail_url
        self.created_at = created_at
        self.updated_at = updated_at
    }
}

struct PendingBookmarkOperation: Codable {
    enum OperationType: String, Codable {
        case create
        case update
        case delete
    }
    
    let id: UUID
    let type: OperationType
    let bookmark: BookmarkDTO?
    let timestamp: Date
    
    init(type: OperationType, bookmark: BookmarkDTO?, id: UUID? = nil) {
        self.type = type
        self.bookmark = bookmark
        self.id = id ?? bookmark?.id ?? UUID()
        self.timestamp = Date()
    }
}
