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
    var thumbnailURL: String?
    var tags: [String] // NEW: Tags array
    
    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        notes: String = "",
        category: String = "general",
        dateAdded: Date = Date(),
        isRead: Bool = false,
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
        self.thumbnailURL = thumbnailURL
        self.tags = tags
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
