//
//  BookmarkCard.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData

struct BookmarkCard: View {
    @Environment(\.modelContext) private var modelContext
    let bookmark: Bookmark
    
    var body: some View {
        cardContent
            .cardGlassStyle()
            .contextMenu {
                contextMenuContent
            }
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category and status
            HStack {
                categoryBadge
                
                Spacer()
                
                if !bookmark.isRead {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                
                Button(action: toggleRead) {
                    Image(systemName: bookmark.isRead ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(bookmark.isRead ? .green : .secondary)
                }
            }
            
            // Title
            Text(bookmark.title)
                .font(.headline)
                .lineLimit(2)
            
            // URL
            Text(bookmark.url)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            // Notes if available
            if !bookmark.notes.isEmpty {
                Text(bookmark.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            
            // Tags if available
            if !bookmark.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(bookmark.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            // Footer with date
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(bookmark.dateAdded, style: .relative)
                    .font(.caption)
                
                Spacer()
                
                Button(action: openURL) {
                    Label("Open", systemImage: "arrow.up.right")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var categoryBadge: some View {
        HStack(spacing: 4) {
            if let category = Category.allCases.first(where: { $0.rawValue.lowercased() == bookmark.category }) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(category.color)
                Text(category.rawValue)
                    .font(.caption)
                    .bold()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    @ViewBuilder
    private var contextMenuContent: some View {
        Button(action: toggleRead) {
            Label(
                bookmark.isRead ? "Mark as Unread" : "Mark as Read",
                systemImage: bookmark.isRead ? "circle" : "checkmark.circle"
            )
        }
        
        Button(action: openURL) {
            Label("Open in Browser", systemImage: "safari")
        }
        
        Divider()
        
        Button(role: .destructive, action: deleteBookmark) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    
    private func toggleRead() {
        withAnimation(.smooth) {
            bookmark.isRead.toggle()
        }
    }
    
    private func openURL() {
        if let url = URL(string: bookmark.url) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
    
    private func deleteBookmark() {
        withAnimation(.smooth) {
            modelContext.delete(bookmark)
        }
    }
}

// MARK: - Card Glass Style Extension

extension View {
    @ViewBuilder
    func cardGlassStyle() -> some View {
        self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Bookmark.self, configurations: config)
    let bookmark = Bookmark.samples[0]
    container.mainContext.insert(bookmark)
    
    return BookmarkCard(bookmark: bookmark)
        .padding()
        .background(.blue.opacity(0.1))
        .modelContainer(container)
        .environment(ThemeManager())
}
