//
//  WidgetDataManager.swift
//  MindShelf
//
//  Syncs bookmark stats to app group for Widget Extension.
//

import Foundation
import WidgetKit

enum WidgetDataManager {
    static let appGroupID = "group.com.muartdev.mind"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func update(unreadCount: Int, totalCount: Int, recentTitles: [String] = []) {
        defaults?.set(unreadCount, forKey: "widget_unread_count")
        defaults?.set(totalCount, forKey: "widget_total_count")
        defaults?.set(recentTitles, forKey: "widget_recent_titles")
        defaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    static var unreadCount: Int {
        defaults?.integer(forKey: "widget_unread_count") ?? 0
    }

    static var totalCount: Int {
        defaults?.integer(forKey: "widget_total_count") ?? 0
    }

    static var recentTitles: [String] {
        defaults?.stringArray(forKey: "widget_recent_titles") ?? []
    }
}
