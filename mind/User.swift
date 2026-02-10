//
//  User.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var email: String
    var name: String
    var avatarURL: String?
    var createdAt: Date
    var notificationsEnabled: Bool
    var reminderTime: Date?
    var isPremium: Bool = false
    var premiumUntil: Date?
    var premiumPurchaseDate: Date?
    var languageCode: String = "en"
    
    init(
        id: UUID = UUID(),
        email: String,
        name: String,
        avatarURL: String? = nil,
        createdAt: Date = Date(),
        notificationsEnabled: Bool = true,
        reminderTime: Date? = nil,
        isPremium: Bool = false,
        premiumUntil: Date? = nil,
        premiumPurchaseDate: Date? = nil,
        languageCode: String = "en"
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarURL = avatarURL
        self.createdAt = createdAt
        self.notificationsEnabled = notificationsEnabled
        self.reminderTime = reminderTime
        self.isPremium = isPremium
        self.premiumUntil = premiumUntil
        self.premiumPurchaseDate = premiumPurchaseDate
        self.languageCode = languageCode
    }
}

extension User {
    static let sample = User(
        email: "user@example.com",
        name: "John Doe",
        createdAt: Date().addingTimeInterval(-86400 * 30)
    )
}
