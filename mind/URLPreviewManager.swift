//
//  URLPreviewManager.swift
//  MindShelf
//
//  Created by Murat on 9.02.2026.
//

import Foundation
import SwiftUI

@MainActor
final class URLPreviewManager {
    static let shared = URLPreviewManager()
    
    private init() {}
    
    struct Preview {
        let title: String?
        let description: String?
        let imageURL: String?
        let faviconURL: String?
    }
    
    // MARK: - Fetch Preview
    
    func fetchPreview(for urlString: String) async throws -> Preview {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // Fetch HTML
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        // Parse Open Graph and Meta tags
        let title = extractMetaTag(html: html, property: "og:title") 
                    ?? extractMetaTag(html: html, name: "twitter:title")
                    ?? extractTitle(html: html)
        
        let description = extractMetaTag(html: html, property: "og:description")
                          ?? extractMetaTag(html: html, name: "twitter:description")
                          ?? extractMetaTag(html: html, name: "description")
        
        let imageURL = extractMetaTag(html: html, property: "og:image")
                      ?? extractMetaTag(html: html, name: "twitter:image")
        
        // Favicon
        let faviconURL = extractFavicon(html: html, baseURL: url)
        
        return Preview(
            title: decodeHTMLEntities(title?.trimmingCharacters(in: .whitespacesAndNewlines)),
            description: decodeHTMLEntities(description?.trimmingCharacters(in: .whitespacesAndNewlines)),
            imageURL: imageURL,
            faviconURL: faviconURL
        )
    }
    
    // MARK: - HTML Parsing
    
    private func decodeHTMLEntities(_ string: String?) -> String? {
        guard let string = string else { return nil }
        
        let entities = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&#39;": "'",
            "&ldquo;": "\"",
            "&rdquo;": "\"",
            "&lsquo;": "'",
            "&rsquo;": "'",
            "&nbsp;": " "
        ]
        
        var result = string
        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        
        return result
    }
    
    private func extractTitle(html: String) -> String? {
        // Extract <title>...</title>
        let pattern = "<title[^>]*>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let nsString = html as NSString
        let results = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
        
        guard let match = results.first,
              match.numberOfRanges > 1 else {
            return nil
        }
        
        return nsString.substring(with: match.range(at: 1))
    }
    
    private func extractMetaTag(html: String, property: String? = nil, name: String? = nil) -> String? {
        var pattern = "<meta[^>]*(?:property|name)=[\"']"
        
        if let property = property {
            pattern += NSRegularExpression.escapedPattern(for: property)
        } else if let name = name {
            pattern += NSRegularExpression.escapedPattern(for: name)
        }
        
        pattern += "[\"'][^>]*content=[\"']([^\"']+)[\"'][^>]*>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let nsString = html as NSString
        let results = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
        
        guard let match = results.first,
              match.numberOfRanges > 1 else {
            return nil
        }
        
        return nsString.substring(with: match.range(at: 1))
    }
    
    private func extractFavicon(html: String, baseURL: URL) -> String? {
        // Try to find <link rel="icon" href="...">
        let pattern = "<link[^>]*rel=[\"'](?:icon|shortcut icon)[\"'][^>]*href=[\"']([^\"']+)[\"'][^>]*>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return "\(baseURL.scheme ?? "https")://\(baseURL.host ?? "")/favicon.ico"
        }
        
        let nsString = html as NSString
        let results = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
        
        guard let match = results.first,
              match.numberOfRanges > 1 else {
            // Fallback to /favicon.ico
            return "\(baseURL.scheme ?? "https")://\(baseURL.host ?? "")/favicon.ico"
        }
        
        let iconPath = nsString.substring(with: match.range(at: 1))
        
        // Make absolute URL if relative
        if iconPath.hasPrefix("http") {
            return iconPath
        } else if iconPath.hasPrefix("//") {
            return "https:\(iconPath)"
        } else if iconPath.hasPrefix("/") {
            return "\(baseURL.scheme ?? "https")://\(baseURL.host ?? "")\(iconPath)"
        } else {
            return "\(baseURL.scheme ?? "https")://\(baseURL.host ?? "")/\(iconPath)"
        }
    }
    
    // MARK: - Category Suggestion
    
    func suggestCategory(for urlString: String) -> Category? {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return nil
        }
        
        if host.contains("twitter.com") || host.contains("x.com") {
            return .twitter
        } else if host.contains("instagram.com") {
            return .instagram
        } else if host.contains("youtube.com") || host.contains("youtu.be") {
            return .youtube
        } else if host.contains("medium.com") || host.contains("dev.to") || host.contains("substack.com") {
            return .article
        } else if host.contains("vimeo.com") || host.contains("dailymotion.com") || host.contains("tiktok.com") {
            return .video
        }
        
        return nil
    }
}
