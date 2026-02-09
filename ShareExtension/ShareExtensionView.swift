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
                        Image(systemName: "bookmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white)
                        
                        Text("Save to MindShelf")
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
                                Text("❌ X").tag("x (twitter)")
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
            }
            .navigationBarHidden(true)
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
        
        // Slight delay for UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onSave()
        }
    }
}
