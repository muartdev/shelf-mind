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
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        return URLSession(configuration: config)
    }()

    // Pre-compiled regex for favicon extraction
    private let faviconRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: "<link[^>]*rel=[\"'](?:icon|shortcut icon)[\"'][^>]*href=[\"']([^\"']+)[\"'][^>]*>",
            options: .caseInsensitive
        )
    }()

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
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        let (data, _) = try await session.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        // Parse Open Graph and Meta tags (using shared HTMLMetaParser)
        let title = normalizeTitle(
            HTMLMetaParser.extractMetaTag(html: html, property: "og:title")
                    ?? HTMLMetaParser.extractMetaTag(html: html, name: "twitter:title")
                    ?? HTMLMetaParser.extractTitle(html: html)
        )
        
        let description = normalizeDescription(
            HTMLMetaParser.extractMetaTag(html: html, property: "og:description")
                          ?? HTMLMetaParser.extractMetaTag(html: html, name: "twitter:description")
                          ?? HTMLMetaParser.extractMetaTag(html: html, name: "description")
        )
        
        let rawImageURL = HTMLMetaParser.extractMetaTag(html: html, property: "og:image")
                      ?? HTMLMetaParser.extractMetaTag(html: html, name: "twitter:image")
        let imageURL = HTMLMetaParser.resolveImageURL(rawImageURL, baseURL: url) ?? rawImageURL
        
        // Favicon
        let faviconURL = extractFavicon(html: html, baseURL: url)
        
        return Preview(
            title: HTMLMetaParser.decodeHTMLEntities(title?.trimmingCharacters(in: .whitespacesAndNewlines)),
            description: HTMLMetaParser.decodeHTMLEntities(description?.trimmingCharacters(in: .whitespacesAndNewlines)),
            imageURL: imageURL,
            faviconURL: faviconURL
        )
    }
    
    // MARK: - HTML Parsing (HTMLMetaParser used for shared logic)

    private func normalizeTitle(_ title: String?) -> String? {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            return nil
        }
        let lower = title.lowercased()
        if lower.contains("browser is deprecated") || lower.contains("please upgrade") {
            return nil
        }
        return title
    }

    private func normalizeDescription(_ description: String?) -> String? {
        guard let description = description?.trimmingCharacters(in: .whitespacesAndNewlines), !description.isEmpty else {
            return nil
        }
        return description
    }
    
    private func extractFavicon(html: String, baseURL: URL) -> String? {
        guard let regex = faviconRegex else {
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
