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
    @Environment(LocalizationManager.self) private var localization
    let bookmark: Bookmark
    var isCompact: Bool = false
    
    var body: some View {
        cardContent
            .cardGlassStyle()
            .contextMenu {
                contextMenuContent
            }
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        Group {
            if isCompact {
                compactLayout
            } else {
                fullLayout
            }
        }
        .padding(isCompact ? 12 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Full Layout (List View)
    
    private var fullLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category and status
            HStack {
                categoryBadge
                
                Spacer()
                

                
                Button(action: toggleRead) {
                    Image(systemName: bookmark.isRead ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(bookmark.isRead ? .green : .secondary)
                }
            }
            
            // Title with Thumbnail
            HStack(alignment: .top, spacing: 12) {
                thumbnailView(size: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.title)
                        .font(.headline)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
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
                Text(bookmark.dateAdded.relativeDisplayString())
                    .font(.caption)
                
                Spacer()
                
                Button(action: openURL) {
                    Label(localization.localizedString("common.open"), systemImage: "arrow.up.right")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Compact Layout (Grid View)
    
    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let thumbnailURL = bookmark.thumbnailURL, !thumbnailURL.isEmpty {
                // Full width image layout
                AsyncImage(url: URL(string: thumbnailURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    case .failure(_), .empty:
                        // Show placeholder ONLY, not full fallback content
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 120)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 120)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(bookmark.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 40, alignment: .topLeading) // Fixed text height
                    
                    HStack {
                        categoryBadge
                        Spacer()
                        readStatusButton
                    }
                }
                .padding(12)
            } else {
                // Original layout for no image
                fallbackCompactContent
                    .padding(10)
            }
        }
        .frame(height: 220) // Fixed total height
    }
    
    private var fallbackCompactContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon Area (Matches Image Height)
            ZStack {
                Color.clear
                thumbnailView(size: 70)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.05))
            
            // Content Area
            VStack(alignment: .leading, spacing: 8) {
                Text(bookmark.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 40, alignment: .topLeading)
                
                HStack {
                    categoryBadge
                    Spacer()
                    readStatusButton
                }
            }
            .padding(12)
        }
    }
    
    private var readStatusButton: some View {
        Button(action: toggleRead) {
            Image(systemName: bookmark.isRead ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(bookmark.isRead ? .green : .secondary)
                .frame(width: 44, height: 44) // Larger touch target
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Thumbnail View
    
    @ViewBuilder
    private func thumbnailView(size: CGFloat) -> some View {
        if let thumbnailURL = bookmark.thumbnailURL, !thumbnailURL.isEmpty {
            AsyncImage(url: URL(string: thumbnailURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                        )
                case .failure(_):
                    faviconFallback(size: size)
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                @unknown default:
                    faviconFallback(size: size)
                }
            }
        } else {
            faviconFallback(size: size)
        }
    }
    
    private func faviconFallback(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.5, blue: 1.0).opacity(0.3),
                            Color(red: 0.6, green: 0.3, blue: 0.9).opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                )
            
            // Extract first letter from title or domain
            Text(extractInitial())
                .font(size > 70 ? .title : .title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
    
    private func extractInitial() -> String {
        // Try to get first letter from title
        if let firstChar = bookmark.title.first {
            return String(firstChar).uppercased()
        }
        
        // Fallback to domain initial
        if let host = URL(string: bookmark.url)?.host {
            if let firstChar = host.first {
                return String(firstChar).uppercased()
            }
        }
        
        return "🔖"
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
                bookmark.isRead ? localization.localizedString("common.mark.unread") : localization.localizedString("common.mark.read"),
                systemImage: bookmark.isRead ? "circle" : "checkmark.circle"
            )
        }
        
        Button(action: openURL) {
            Label(localization.localizedString("common.open.browser"), systemImage: "safari")
        }
        
        Divider()
        
        Button(role: .destructive, action: deleteBookmark) {
            Label(localization.localizedString("common.delete"), systemImage: "trash")
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
        self.background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
