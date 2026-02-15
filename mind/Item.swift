//
//  Bookmark.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import Foundation
import SwiftUI
import SwiftData

/// Represents a saved bookmark with metadata
@Model
final class Bookmark {
    var id: UUID
    var title: String
    var url: String
    var notes: String
    var category: String
    var dateAdded: Date
    var isRead: Bool
    var isFavorite: Bool
    var thumbnailURL: String?
    var tags: [String]
    
    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        notes: String = "",
        category: String = "general",
        dateAdded: Date = Date(),
        isRead: Bool = false,
        isFavorite: Bool = false,
        thumbnailURL: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.notes = notes
        self.category = category
        self.dateAdded = dateAdded
        self.isRead = isRead
        self.isFavorite = isFavorite
        self.thumbnailURL = thumbnailURL
        self.tags = tags
    }
}

extension Bookmark {
    static func dedupeKey(_ urlString: String) -> String {
        let normalized = normalizedURLString(urlString)
        if let tweetID = tweetID(from: normalized) {
            return "tweet:\(tweetID)"
        }
        return normalized
    }

    private static func tweetID(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased(),
              host.contains("twitter.com") || host.contains("x.com") else {
            return nil
        }

        let parts = url.path.split(separator: "/").map(String.init)
        for (index, part) in parts.enumerated() {
            if part == "status" || part == "statuses" {
                let nextIndex = index + 1
                guard nextIndex < parts.count else { continue }
                let id = parts[nextIndex]
                if !id.isEmpty, id.allSatisfy({ $0.isNumber }) {
                    return id
                }
            }
        }

        if let iIndex = parts.firstIndex(of: "i"), iIndex + 2 < parts.count, parts[iIndex + 1] == "status" {
            let id = parts[iIndex + 2]
            if !id.isEmpty, id.allSatisfy({ $0.isNumber }) {
                return id
            }
        }

        return nil
    }

    static func normalizedURLString(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed) else {
            return trimmed.lowercased()
        }
        
        components.fragment = nil
        if let scheme = components.scheme?.lowercased() {
            components.scheme = scheme
        }
        if let host = components.host?.lowercased() {
            var normalizedHost = host
            if normalizedHost.hasPrefix("www.") {
                normalizedHost.removeFirst(4)
            }
            components.host = normalizedHost
        }
        if let port = components.port {
            if (components.scheme == "http" && port == 80) || (components.scheme == "https" && port == 443) {
                components.port = nil
            }
        }
        
        var path = components.path
        if path.count > 1, path.hasSuffix("/") {
            path.removeLast()
            components.path = path
        }
        
        if var items = components.queryItems {
            let trackingParams: Set<String> = [
                "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
                "fbclid", "gclid", "igshid"
            ]
            items = items.filter { !trackingParams.contains($0.name.lowercased()) }
            items.sort { ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "") }
            components.queryItems = items.isEmpty ? nil : items
        }
        
        return components.string ?? trimmed.lowercased()
    }
}

/// Categories for organizing bookmarks
enum Category: String, CaseIterable, Identifiable {
    case twitter = "X (Twitter)"
    case instagram = "Instagram"
    case youtube = "YouTube"
    case article = "Article"
    case video = "Video"
    case general = "General"
    
    var id: String { rawValue }

    /// Stable storage key used in persistence and sync.
    var storageKey: String {
        switch self {
        case .twitter: return "x"
        case .instagram: return "instagram"
        case .youtube: return "youtube"
        case .article: return "article"
        case .video: return "video"
        case .general: return "general"
        }
    }

    /// Map a stored value to a category, accepting legacy values.
    static func fromStoredValue(_ value: String) -> Category? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let match = allCases.first(where: { $0.storageKey == normalized }) {
            return match
        }
        return allCases.first(where: { $0.rawValue.lowercased() == normalized })
    }
    
    var shortName: String {
        switch self {
        case .twitter: return "X"
        case .instagram: return "Instagram"
        case .youtube: return "YouTube"
        case .article: return "Article"
        case .video: return "Video"
        case .general: return "General"
        }
    }

    /// Display name for filter chips (clearer than shortName for X/Twitter)
    var filterDisplayName: String {
        switch self {
        case .twitter: return "X (Twitter)"
        default: return shortName
        }
    }
    
    var icon: String {
        switch self {
        case .twitter: return "xmark.app.fill"  // X logo style
        case .instagram: return "camera.circle.fill"
        case .youtube: return "play.rectangle.fill"
        case .article: return "doc.text.fill"
        case .video: return "film.fill"
        case .general: return "bookmark.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .twitter: return .black
        case .instagram: return .pink
        case .youtube: return .red
        case .article: return .blue
        case .video: return .purple
        case .general: return .gray
        }
    }
}

extension Array where Element == Bookmark {
    func containsDuplicate(of url: String) -> Bool {
        let key = Bookmark.dedupeKey(url)
        return contains(where: { Bookmark.dedupeKey($0.url) == key })
    }

    func findDuplicate(of url: String) -> Bookmark? {
        let key = Bookmark.dedupeKey(url)
        return first(where: { Bookmark.dedupeKey($0.url) == key })
    }
}

// Sample data for preview
extension Bookmark {
    static let samples: [Bookmark] = [
        Bookmark(
            title: "SwiftUI State Management",
            url: "https://developer.apple.com/documentation/swiftui",
            notes: "Important article about @Observable",
            category: "article",
            dateAdded: Date().addingTimeInterval(-86400 * 2),
            tags: ["swiftui", "ios", "development"]
        ),
        Bookmark(
            title: "WWDC 2025 Highlights",
            url: "https://youtube.com/watch?v=example",
            notes: "Must watch for iOS 26 updates",
            category: "youtube",
            dateAdded: Date().addingTimeInterval(-86400 * 5),
            isRead: true,
            tags: ["wwdc", "apple", "keynote"]
        ),
        Bookmark(
            title: "Great thread on Swift Concurrency",
            url: "https://twitter.com/example/status/123",
            notes: "Explains async/await patterns",
            category: "twitter",
            dateAdded: Date().addingTimeInterval(-86400),
            tags: ["swift", "concurrency", "async"]
        ),
        Bookmark(
            title: "Amazing iOS Design Tips",
            url: "https://instagram.com/p/example",
            notes: "Beautiful UI inspiration",
            category: "instagram",
            dateAdded: Date().addingTimeInterval(-3600),
            tags: ["design", "ui", "inspiration"]
        )
    ]
}
