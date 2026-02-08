//
//  ContentView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AuthManager.self) private var authManager
    @Query(sort: \Bookmark.dateAdded, order: .reverse) private var bookmarks: [Bookmark]
    
    @State private var showingAddBookmark = false
    @State private var selectedBookmark: Bookmark?
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showOnlyUnread = false
    @State private var isLoadingFromSupabase = false
    
    var filteredBookmarks: [Bookmark] {
        var result = bookmarks
        
        // Filter by category
        if let selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // Filter by read status
        if showOnlyUnread {
            result = result.filter { !$0.isRead }
        }
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { bookmark in
                bookmark.title.localizedStandardContains(searchText) ||
                bookmark.notes.localizedStandardContains(searchText) ||
                bookmark.url.localizedStandardContains(searchText)
            }
        }
        
        return result
    }
    
    var unreadCount: Int {
        bookmarks.filter { !$0.isRead }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient - themed
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if filteredBookmarks.isEmpty {
                    emptyStateView
                } else {
                    bookmarkListView
                }
            }
            .navigationTitle("MindShelf")
            .toolbar {
                toolbarContent
            }
            .searchable(text: $searchText, prompt: "Search bookmarks")
            .sheet(isPresented: $showingAddBookmark) {
                AddBookmarkView()
            }
            .sheet(item: $selectedBookmark) { bookmark in
                BookmarkDetailView(bookmark: bookmark)
            }
            .task {
                await loadBookmarksFromSupabase()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var bookmarkListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                filterChipsView
                
                ForEach(filteredBookmarks) { bookmark in
                    BookmarkCard(bookmark: bookmark)
                        .onTapGesture {
                            selectedBookmark = bookmark
                        }
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .refreshable {
            // Pull to refresh - reload data
            await refreshBookmarks()
        }
    }
    
    private func refreshBookmarks() async {
        // Simulate refresh - in real app, sync with Supabase
        try? await Task.sleep(for: .seconds(1))
    }
    
    @ViewBuilder
    private var filterChipsView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(Category.allCases) { category in
                    let count = bookmarks.filter { $0.category == category.rawValue.lowercased() }.count
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        count: count > 0 ? count : nil,
                        isSelected: selectedCategory == category.rawValue.lowercased(),
                        action: {
                            selectedCategory = selectedCategory == category.rawValue.lowercased() ? nil : category.rawValue.lowercased()
                        }
                    )
                }
                
                FilterChip(
                    title: "Unread",
                    icon: "circle.badge",
                    count: unreadCount > 0 ? unreadCount : nil,
                    isSelected: showOnlyUnread,
                    action: { showOnlyUnread.toggle() }
                )
            }
            .padding(.horizontal, 4)
        }
        .scrollIndicators(.hidden)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedCategory != nil || showOnlyUnread ? "tray" : "bookmark.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(emptyStateTitle)
                .font(.title2)
                .bold()
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if selectedCategory != nil || showOnlyUnread {
                Button(action: clearFilters) {
                    Label("Clear Filters", systemImage: "xmark.circle")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .glassButtonStyle()
            } else {
                Button(action: { showingAddBookmark = true }) {
                    Label("Add Your First Bookmark", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .glassButtonStyle()
            }
        }
    }
    
    private var emptyStateTitle: String {
        if selectedCategory != nil {
            return "No Bookmarks in This Category"
        } else if showOnlyUnread {
            return "All Caught Up!"
        } else {
            return "No Bookmarks Yet"
        }
    }
    
    private var emptyStateMessage: String {
        if selectedCategory != nil {
            return "Try adding a bookmark with this category or clear the filter to see all"
        } else if showOnlyUnread {
            return "You've read all your bookmarks. Great job!"
        } else {
            return "Save interesting content from X, articles, and videos to read later"
        }
    }
    
    private func clearFilters() {
        selectedCategory = nil
        showOnlyUnread = false
    }
    
    // MARK: - Supabase Sync
    
    private func loadBookmarksFromSupabase() async {
        guard !isLoadingFromSupabase else { return }
        guard let userId = authManager.currentUser?.id else {
            print("⚠️ No user logged in, skipping Supabase fetch")
            return
        }
        
        isLoadingFromSupabase = true
        defer { isLoadingFromSupabase = false }
        
        do {
            let supabaseBookmarks = try await SupabaseManager.shared.fetchBookmarks(userId: userId)
            print("✅ Fetched \(supabaseBookmarks.count) bookmarks from Supabase")
            
            // Sync to local SwiftData
            for dto in supabaseBookmarks {
                // Check if bookmark already exists locally
                let existsLocally = bookmarks.contains(where: { $0.id == dto.id })
                
                if !existsLocally {
                    let bookmark = Bookmark(
                        id: dto.id,
                        title: dto.title,
                        url: dto.url,
                        notes: dto.notes,
                        category: dto.category,
                        dateAdded: dto.created_at ?? Date(),
                        isRead: dto.is_read,
                        thumbnailURL: dto.thumbnail_url,
                        tags: dto.tags
                    )
                    modelContext.insert(bookmark)
                }
            }
            
            try modelContext.save()
            print("✅ Synced bookmarks to local database")
        } catch {
            print("❌ Failed to load bookmarks from Supabase: \(error)")
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { showingAddBookmark = true }) {
                Image(systemName: "plus")
                    .font(.headline)
            }
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let icon: String
    var count: Int?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.smooth) {
                action()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                
                Text(title)
                    .font(.subheadline)
                    .bold()
                
                if let count {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .chipStyle(isSelected: isSelected)
    }
}

// MARK: - View Extension for Styles

extension View {
    @ViewBuilder
    func glassButtonStyle() -> some View {
        self.buttonStyle(.borderedProminent)
    }
    
    @ViewBuilder
    func chipStyle(isSelected: Bool) -> some View {
        self.background(
            isSelected ? .ultraThinMaterial : .thinMaterial,
            in: Capsule()
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Bookmark.self, inMemory: true)
        .environment(ThemeManager())
}
