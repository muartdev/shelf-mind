//
//  ShareExtensionView.swift
//  ShareExtension
//
//  Created by Murat on 9.02.2026.
//

import SwiftUI

struct ShareExtensionView: View {
    let url: String
    let suggestedTitle: String?
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var category: String = "general"
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var previewImageURL: String?
    @State private var isLoadingPreview = true
    @State private var duplicateMessage: String?

    private var isTurkish: Bool {
        UserDefaults(suiteName: "group.com.muartdev.mind")?.string(forKey: "app_language") == "tr"
            || Locale.current.language.languageCode?.identifier == "tr"
    }

    private func loc(_ en: String, _ tr: String) -> String {
        isTurkish ? tr : en
    }

    private let categories: [(icon: String, label: String, value: String)] = [
        ("globe", "General", "general"),
        ("x.circle", "X", "x"),
        ("camera", "Instagram", "instagram"),
        ("play.rectangle", "YouTube", "youtube"),
        ("doc.text", "Article", "article"),
        ("film", "Video", "video"),
    ]

    init(url: String, suggestedTitle: String?, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.url = url
        self.suggestedTitle = suggestedTitle
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: suggestedTitle ?? "")
    }

    private var isSignedIn: Bool {
        UserDefaults(suiteName: "group.com.muartdev.mind")?.bool(forKey: "isAuthenticated") ?? false
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 0) {
                if !isSignedIn {
                    signInBanner
                }
                cardContent
                    .frame(maxHeight: 520)
                    .padding(.horizontal, 12)
            }

            // Success Overlay
            if showSuccess {
                successOverlay
            }
        }
        .onAppear { suggestInfo() }
    }

    private var signInBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.subheadline)
            Text(loc("Sign in to MindShelf to sync bookmarks across devices.", "Yer imlerini cihazlar arasında senkronize etmek için MindShelf'e giriş yapın."))
                .font(.caption)
                .lineLimit(2)
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(Color.orange.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(spacing: 0) {
            // Header bar
            headerBar

            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 16) {
                    // Duplicate warning
                    if let duplicateMessage {
                        duplicateBanner(message: duplicateMessage)
                    }

                    // URL Preview Card
                    urlPreviewCard

                    // Title field
                    titleField

                    // Category picker
                    categoryPicker
                }
                .padding(20)
            }
        }
        .modifier(GlassCardModifier())
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: onCancel) {
                Text(loc("Cancel", "İptal"))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(loc("Save to Mind Shelf", "Mind Shelf'e Kaydet"))
                .font(.headline)

            Spacer()

            Button(action: saveBookmark) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(loc("Save", "Kaydet"))
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .disabled(isSaving || title.isEmpty || duplicateMessage != nil)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - URL Preview

    private var urlPreviewCard: some View {
        HStack(spacing: 14) {
            // Thumbnail
            Group {
                if let imageURL = previewImageURL, let imgURL = URL(string: imageURL) {
                    AsyncImage(url: imgURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            placeholderIcon
                        }
                    }
                } else if isLoadingPreview {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    placeholderIcon
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            // URL info
            VStack(alignment: .leading, spacing: 4) {
                if !title.isEmpty {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
                Text(shortenedURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(14)
        .modifier(GlassInnerModifier())
    }

    // MARK: - Title Field

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc("Title", "Başlık"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            TextField(loc("Enter a title", "Başlık girin"), text: $title)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc("Category", "Kategori"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(categories, id: \.value) { cat in
                    Button(action: { withAnimation(.smooth(duration: 0.2)) { category = cat.value } }) {
                        VStack(spacing: 5) {
                            Image(systemName: cat.icon)
                                .font(.title3)
                            Text(cat.label)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .modifier(CategoryChipModifier(isSelected: category == cat.value))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(category == cat.value ? .blue : .primary)
                }
            }
        }
    }

    // MARK: - Duplicate Banner

    private func duplicateBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 0.5)
        )
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: showSuccess)

            Text(loc("Saved!", "Kaydedildi!"))
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .transition(.opacity)
    }

    // MARK: - Helpers

    private var placeholderIcon: some View {
        ZStack {
            Color.white.opacity(0.06)
            Image(systemName: "bookmark.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var shortenedURL: String {
        URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") ?? url
    }

    // MARK: - Save

    private func saveBookmark() {
        guard !title.isEmpty else { return }
        isSaving = true

        let defaults = UserDefaults(suiteName: "group.com.muartdev.mind")

        var bookmarkData: [String: Any] = [
            "title": title,
            "url": url,
            "category": category,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let imageURL = previewImageURL {
            bookmarkData["thumbnailURL"] = imageURL
        }

        var pendingBookmarks = defaults?.array(forKey: "pendingBookmarks") as? [[String: Any]] ?? []
        pendingBookmarks.append(bookmarkData)
        defaults?.set(pendingBookmarks, forKey: "pendingBookmarks")
        defaults?.synchronize()

        withAnimation(.spring()) {
            showSuccess = true
            isSaving = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onSave()
        }
    }

    // MARK: - URL Info

    private func suggestInfo() {
        let lowercasedURL = url.lowercased()
        if lowercasedURL.contains("twitter.com") || lowercasedURL.contains("x.com") {
            category = "x"
        } else if lowercasedURL.contains("instagram.com") {
            category = "instagram"
        } else if lowercasedURL.contains("youtube.com") || lowercasedURL.contains("youtu.be") {
            category = "youtube"
        } else if lowercasedURL.contains("medium.com") || lowercasedURL.contains("substack.com") {
            category = "article"
        }

        checkDuplicate()
        fetchPreview()
    }

    private func checkDuplicate() {
        let defaults = UserDefaults(suiteName: "group.com.muartdev.mind")
        let dedupeKey = Self.dedupeKey(url)

        // Check against saved bookmarks from main app
        if let savedURLs = defaults?.dictionary(forKey: "savedBookmarkURLs") as? [String: Double],
           let timestamp = savedURLs[dedupeKey] {
            let date = Date(timeIntervalSince1970: timestamp)
            let dateStr = Self.relativeDate(date)
            duplicateMessage = loc(
                "This URL is already saved (\(dateStr)).",
                "Bu URL zaten kaydedilmiş (\(dateStr))."
            )
            return
        }

        // Check against pending bookmarks not yet imported
        if let pending = defaults?.array(forKey: "pendingBookmarks") as? [[String: Any]] {
            for entry in pending {
                guard let entryURL = entry["url"] as? String else { continue }
                if Self.dedupeKey(entryURL) == dedupeKey {
                    let dateStr: String
                    if let ts = entry["timestamp"] as? Double {
                        dateStr = Self.relativeDate(Date(timeIntervalSince1970: ts))
                    } else {
                        dateStr = loc("recently", "yakın zamanda")
                    }
                    duplicateMessage = loc(
                        "This URL is already saved (\(dateStr)).",
                        "Bu URL zaten kaydedilmiş (\(dateStr))."
                    )
                    return
                }
            }
        }
    }

    private static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Simplified URL normalization matching Bookmark.dedupeKey logic
    private static func dedupeKey(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle tweet IDs
        if let url = URL(string: trimmed),
           let host = url.host?.lowercased(),
           host.contains("twitter.com") || host.contains("x.com") {
            let parts = url.path.split(separator: "/").map(String.init)
            for (index, part) in parts.enumerated() {
                if (part == "status" || part == "statuses"), index + 1 < parts.count {
                    let id = parts[index + 1]
                    if !id.isEmpty, id.allSatisfy({ $0.isNumber }) {
                        return "tweet:\(id)"
                    }
                }
            }
        }

        guard var components = URLComponents(string: trimmed) else {
            return trimmed.lowercased()
        }
        components.fragment = nil
        if let scheme = components.scheme?.lowercased() { components.scheme = scheme }
        if let host = components.host?.lowercased() {
            var h = host
            if h.hasPrefix("www.") { h.removeFirst(4) }
            components.host = h
        }
        if let port = components.port {
            if (components.scheme == "http" && port == 80) || (components.scheme == "https" && port == 443) {
                components.port = nil
            }
        }
        var path = components.path
        if path.count > 1, path.hasSuffix("/") { path.removeLast(); components.path = path }
        if var items = components.queryItems {
            let tracking: Set<String> = ["utm_source","utm_medium","utm_campaign","utm_term","utm_content","fbclid","gclid","igshid"]
            items = items.filter { !tracking.contains($0.name.lowercased()) }
            items.sort { ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "") }
            components.queryItems = items.isEmpty ? nil : items
        }
        return components.string ?? trimmed.lowercased()
    }

    private func fetchPreview() {
        guard let requestURL = URL(string: url) else {
            isLoadingPreview = false
            return
        }

        Task {
            do {
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 10
                config.timeoutIntervalForResource = 15
                let session = URLSession(configuration: config)

                var request = URLRequest(url: requestURL)
                request.setValue(
                    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
                    forHTTPHeaderField: "User-Agent"
                )
                request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

                let (data, response) = try await session.data(for: request)

                let html: String
                if let utf8 = String(data: data, encoding: .utf8) {
                    html = utf8
                } else if let latin1 = String(data: data, encoding: .isoLatin1) {
                    html = latin1
                } else {
                    await MainActor.run { isLoadingPreview = false }
                    return
                }

                let fetchedTitle = extractMeta(html: html, key: "og:title")
                    ?? extractMeta(html: html, key: "twitter:title")
                    ?? extractHTMLTitle(from: html)

                let imageURL = resolveImageURL(
                    extractMeta(html: html, key: "og:image")
                        ?? extractMeta(html: html, key: "twitter:image"),
                    responseURL: response.url ?? requestURL
                )

                await MainActor.run {
                    if self.title.isEmpty, let fetchedTitle {
                        self.title = fetchedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    if let imageURL, !imageURL.isEmpty {
                        self.previewImageURL = imageURL
                    }
                    isLoadingPreview = false
                }
            } catch {
                await MainActor.run { isLoadingPreview = false }
            }
        }
    }

    private func resolveImageURL(_ imageURL: String?, responseURL: URL) -> String? {
        guard let imageURL, !imageURL.isEmpty else { return nil }
        if imageURL.hasPrefix("http") { return imageURL }
        if imageURL.hasPrefix("//") { return "https:\(imageURL)" }
        var base = URLComponents(url: responseURL, resolvingAgainstBaseURL: false)
        base?.path = ""
        base?.query = nil
        base?.fragment = nil
        guard let baseStr = base?.string else { return imageURL }
        if imageURL.hasPrefix("/") {
            return baseStr + imageURL
        }
        return baseStr + "/" + imageURL
    }

    // MARK: - HTML Parsing
    // Note: Main app uses HTMLMetaParser (mind/HTMLMetaParser.swift). Share Extension
    // has its own implementation due to target separation; logic mirrors HTMLMetaParser.

    private func extractMeta(html: String, key: String) -> String? {
        let escapedKey = NSRegularExpression.escapedPattern(for: key)
        let pattern1 = "<meta[^>]*(?:property|name)=[\"']\(escapedKey)[\"'][^>]*content=[\"']([^\"']+)[\"'][^>]*>"
        let pattern2 = "<meta[^>]*content=[\"']([^\"']+)[\"'][^>]*(?:property|name)=[\"']\(escapedKey)[\"'][^>]*>"

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

    private func extractHTMLTitle(from html: String) -> String? {
        let pattern = "<title[^>]*>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let nsString = html as NSString
        let results = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
        guard let match = results.first, match.numberOfRanges > 1 else { return nil }
        return nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Glass Modifiers

/// Main card background - uses iOS 26 liquid glass when available, falls back to material
private struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.2), radius: 30, y: 15)
        } else {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.25), radius: 30, y: 15)
        }
    }
}

/// Inner card elements - subtle glass layer
private struct GlassInnerModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        } else {
            content
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
}

/// Category chip with glass styling
private struct CategoryChipModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(
                    isSelected ? Color.blue.opacity(0.15) : Color.white.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .glassEffect(isSelected ? .regular.tint(.blue) : .regular, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected ? Color.blue.opacity(0.4) : Color.clear,
                            lineWidth: 1
                        )
                )
        } else {
            content
                .background(
                    isSelected ? Color.blue.opacity(0.12) : Color.white.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected ? Color.blue.opacity(0.4) : Color.white.opacity(0.08),
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                )
        }
    }
}
