//
//  BookmarkURLNormalizer.swift
//  MindShelf
//
//  Pure URL normalization utilities — Foundation only, no SwiftUI/SwiftData dependencies.
//  Extracted for testability via SPM.
//

import Foundation

/// Pure URL normalization and deduplication utilities.
enum BookmarkURLNormalizer {

    /// Generate a deduplication key for the given URL.
    /// Twitter/X status URLs are keyed by tweet ID so that
    /// `twitter.com/…/status/123` and `x.com/…/status/123` match.
    static func dedupeKey(_ urlString: String) -> String {
        let normalized = normalizedURLString(urlString)
        if let id = tweetID(from: normalized) {
            return "tweet:\(id)"
        }
        return normalized
    }

    /// Extract a numeric tweet ID from a Twitter / X status URL.
    static func tweetID(from urlString: String) -> String? {
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

        if let iIndex = parts.firstIndex(of: "i"),
           iIndex + 2 < parts.count,
           parts[iIndex + 1] == "status" {
            let id = parts[iIndex + 2]
            if !id.isEmpty, id.allSatisfy({ $0.isNumber }) {
                return id
            }
        }

        return nil
    }

    /// Normalize a URL string for comparison:
    /// – lowercase scheme & host
    /// – strip `www.`
    /// – remove default ports (80/443)
    /// – remove trailing slash
    /// – remove fragment
    /// – strip tracking parameters (utm_*, fbclid, gclid, igshid)
    /// – sort remaining query parameters
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
            if (components.scheme == "http" && port == 80) ||
               (components.scheme == "https" && port == 443) {
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

    /// Suggest a bookmark category based on the URL's host.
    static func suggestCategory(for urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return nil
        }

        if host.contains("twitter.com") || host.contains("x.com") {
            return "x"
        } else if host.contains("instagram.com") {
            return "instagram"
        } else if host.contains("youtube.com") || host.contains("youtu.be") {
            return "youtube"
        } else if host.contains("medium.com") || host.contains("dev.to") || host.contains("substack.com") {
            return "article"
        } else if host.contains("vimeo.com") || host.contains("dailymotion.com") || host.contains("tiktok.com") {
            return "video"
        }

        return nil
    }

    /// Map a stored category value to its canonical storage key, accepting legacy values.
    static func normalizeCategory(_ value: String) -> String {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Storage key mapping
        let storageKeys = ["x", "instagram", "youtube", "article", "video", "general"]
        if storageKeys.contains(normalized) {
            return normalized
        }

        // Legacy raw-value mapping
        let legacyMap: [String: String] = [
            "x (twitter)": "x",
            "twitter": "x",
        ]
        if let mapped = legacyMap[normalized] {
            return mapped
        }

        return normalized
    }

    // MARK: - Paywall Logic (pure, no StoreKit dependency)

    static let freeBookmarkLimit = 10
    static let freeURLPreviewLimit = 5

    static func canAddBookmark(currentCount: Int, isPremium: Bool) -> Bool {
        isPremium || currentCount < freeBookmarkLimit
    }

    static func canUseURLPreview(currentCount: Int, isPremium: Bool) -> Bool {
        isPremium || currentCount < freeURLPreviewLimit
    }
}
