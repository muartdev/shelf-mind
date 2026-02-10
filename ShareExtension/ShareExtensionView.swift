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
    
    // Simple local localization for extension
    private var isTurkish: Bool {
        Locale.current.language.languageCode?.identifier == "tr"
    }
    
    private func loc(_ en: String, _ tr: String) -> String {
        isTurkish ? tr : en
    }
    
    init(url: String, suggestedTitle: String?, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.url = url
        self.suggestedTitle = suggestedTitle
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize title with suggested title or empty
        _title = State(initialValue: suggestedTitle ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.5, blue: 1.0),
                        Color(red: 0.6, green: 0.3, blue: 0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image("mindshelf_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                        
                        Text(loc("Save to MindShelf", "MindShelf'e Kaydet"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 32)
                    
                    // Form
                    VStack(spacing: 16) {
                        // URL (read-only)
                        VStack(alignment: .leading, spacing: 8) {
                            Label("URL", systemImage: "link")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text(url)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(2)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Title", systemImage: "text.quote")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            TextField("Enter title", text: $title)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Category", systemImage: "folder")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Picker("Category", selection: $category) {
                                Text("📱 General").tag("general")
                                Text("❌ X").tag("x")
                                Text("📸 Instagram").tag("instagram")
                                Text("▶️ YouTube").tag("youtube")
                                Text("📄 Article").tag("article")
                                Text("🎬 Video").tag("video")
                            }
                            .pickerStyle(.menu)
                            .padding(12)
                            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                            .tint(.white)
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    
                    // Buttons
                    HStack(spacing: 16) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button(action: saveBookmark) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save")
                                        .font(.headline)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                        }
                        .disabled(isSaving || title.isEmpty)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
                .blur(radius: showSuccess ? 10 : 0)
                
                // Success Overlay
                if showSuccess {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce, value: showSuccess)
                        
                        Text(loc("Saved Successfully!", "Başarıyla Kaydedildi!"))
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.4))
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                suggestInfo()
            }
        }
    }
    
    private func saveBookmark() {
        guard !title.isEmpty else { return }
        
        isSaving = true
        
        // Save to App Group UserDefaults for main app to pick up
        let defaults = UserDefaults(suiteName: "group.com.muartdev.mind")
        
        let bookmarkData: [String: Any] = [
            "title": title,
            "url": url,
            "category": category,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        var pendingBookmarks = defaults?.array(forKey: "pendingBookmarks") as? [[String: Any]] ?? []
        pendingBookmarks.append(bookmarkData)
        defaults?.set(pendingBookmarks, forKey: "pendingBookmarks")
        defaults?.synchronize()
        
        // Success feedback
        withAnimation(.spring()) {
            showSuccess = true
            isSaving = false
        }
        
        // Finalize
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onSave()
        }
    }
    
    private func suggestInfo() {
        // Suggest category based on URL
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
        
        // Fetch title if missing
        if title.isEmpty {
            fetchTitle()
        }
    }
    
    private func fetchTitle() {
        guard let url = URL(string: url) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let html = String(data: data, encoding: .utf8) {
                    // Very basic extraction for extension (to avoid code duplication or heavy dependencies)
                    if let fetchedTitle = extractTitle(from: html) {
                        DispatchQueue.main.async {
                            if self.title.isEmpty {
                                self.title = fetchedTitle
                            }
                        }
                    }
                }
            } catch {
                print("Failed to fetch title in extension: \(error)")
            }
        }
    }
    
    private func extractTitle(from html: String) -> String? {
        let pattern = "<title[^>]*>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let nsString = html as NSString
        let results = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
        guard let match = results.first, match.numberOfRanges > 1 else { return nil }
        return nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
