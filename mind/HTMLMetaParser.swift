//
//  HTMLMetaParser.swift
//  MindShelf
//
//  Shared Open Graph / meta tag parsing utility.
//  Used by URLPreviewManager. ShareExtension has its own copy due to target separation.
//

import Foundation

enum HTMLMetaParser {
    /// Extract meta tag value by property (og:*) or name (twitter:*, description)
    static func extractMetaTag(html: String, property: String? = nil, name: String? = nil) -> String? {
        let key: String
        if let property = property {
            key = NSRegularExpression.escapedPattern(for: property)
        } else if let name = name {
            key = NSRegularExpression.escapedPattern(for: name)
        } else {
            return nil
        }

        let pattern1 = "<meta[^>]*(?:property|name)=[\"']\(key)[\"'][^>]*content=[\"']([^\"']+)[\"'][^>]*>"
        let pattern2 = "<meta[^>]*content=[\"']([^\"']+)[\"'][^>]*(?:property|name)=[\"']\(key)[\"'][^>]*>"

        for pattern in [pattern1, pattern2] {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let nsString = html as NSString
            let results = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
            if let match = results.first, match.numberOfRanges > 1 {
                let value = nsString.substring(with: match.range(at: 1))
                if !value.isEmpty { return value }
            }
        }
        return nil
    }

    /// Extract <title>...</title>
    static func extractTitle(html: String) -> String? {
        let pattern = "<title[^>]*>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let nsString = html as NSString
        let results = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
        guard let match = results.first, match.numberOfRanges > 1 else { return nil }
        return nsString.substring(with: match.range(at: 1))
    }

    /// Resolve relative image URL to absolute
    static func resolveImageURL(_ imageURL: String?, baseURL: URL) -> String? {
        guard let imageURL, !imageURL.isEmpty else { return nil }
        if imageURL.hasPrefix("http") { return imageURL }
        if imageURL.hasPrefix("//") { return "https:\(imageURL)" }
        var base = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        base?.path = ""
        base?.query = nil
        base?.fragment = nil
        guard let baseStr = base?.string else { return imageURL }
        if imageURL.hasPrefix("/") {
            return baseStr + imageURL
        }
        return baseStr + "/" + imageURL
    }

    /// Decode common HTML entities
    static func decodeHTMLEntities(_ string: String?) -> String? {
        guard let string else { return nil }
        let entities = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&apos;": "'",
            "&#39;": "'", "&ldquo;": "\"", "&rdquo;": "\"", "&lsquo;": "'", "&rsquo;": "'", "&nbsp;": " "
        ]
        var result = string
        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        return result
    }
}
