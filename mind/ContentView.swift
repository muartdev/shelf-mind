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
    @Environment(LocalizationManager.self) private var localization
    @Query(sort: \Bookmark.dateAdded, order: .reverse) private var bookmarks: [Bookmark]
    
    @State private var showingAddBookmark = false
    @State private var selectedBookmark: Bookmark?
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showOnlyUnread = false
    @State private var isLoadingFromSupabase = false
    @State private var viewMode: ViewMode = .list
    
    enum ViewMode {
        case list
        case grid
    }
    
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
                    EmptyStateView(
                        icon: selectedCategory != nil || showOnlyUnread ? "tray" : "bookmark.slash",
                        title: emptyStateTitle,
                        message: emptyStateMessage,
                        buttonTitle: selectedCategory != nil || showOnlyUnread ? localization.localizedString("main.clear.filters") : localization.localizedString("main.add.first"),
                        action: {
                            if selectedCategory != nil || showOnlyUnread {
                                clearFilters()
                            } else {
                                showingAddBookmark = true
                            }
                        }
                    )
                } else {
                    bookmarkListView
                }
            }
            .navigationTitle(localization.localizedString("main.title"))
            .toolbar {
                toolbarContent
            }
            .searchable(text: $searchText, prompt: localization.localizedString("main.search"))
            .sheet(isPresented: $showingAddBookmark) {
                AddBookmarkView()
            }
            .sheet(item: $selectedBookmark) { bookmark in
                BookmarkDetailView(bookmark: bookmark)
            }
            .task {
                await loadBookmarksFromSupabase()
                loadPendingBookmarksFromShareExtension()
                syncSavedURLsToAppGroup()
            }
            .onAppear {
                loadPendingBookmarksFromShareExtension()
                syncSavedURLsToAppGroup()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var bookmarkListView: some View {
        VStack(spacing: 0) {
            // Sticky Filter Header
            filterChipsView
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .zIndex(1) // Ensure it sits on top of scrolling content
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 16) {
                    if viewMode == .list {
                        listLayout
                    } else {
                        gridLayout
                    }
                }
                .padding()
                .padding(.top, 4) // Add a little spacing from the sticky header
            }
            .scrollIndicators(.hidden)
            .refreshable {
                // Pull to refresh - reload data
                await refreshBookmarks()
            }
        }
    }
    
    private var listLayout: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredBookmarks) { bookmark in
                BookmarkCard(bookmark: bookmark)
                    .onTapGesture {
                        selectedBookmark = bookmark
                    }
            }
        }
    }
    
    private var gridLayout: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(filteredBookmarks) { bookmark in
                BookmarkCard(bookmark: bookmark, isCompact: true)
                    .onTapGesture {
                        selectedBookmark = bookmark
                    }
            }
        }
    }
    
    private func refreshBookmarks() async {
        await loadBookmarksFromSupabase()
        loadPendingBookmarksFromShareExtension()
    }
    
    @ViewBuilder
    private var filterChipsView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                FilterChip(
                    title: localization.localizedString("main.filter.all"),
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(Category.allCases) { category in
                    let count = bookmarks.filter { $0.category == category.storageKey }.count
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        count: count > 0 ? count : nil,
                        isSelected: selectedCategory == category.storageKey,
                        action: {
                            selectedCategory = selectedCategory == category.storageKey ? nil : category.storageKey
                        }
                    )
                }
                
                FilterChip(
                    title: localization.localizedString("main.filter.unread"),
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
                    Label(localization.localizedString("main.clear.filters"), systemImage: "xmark.circle")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .glassButtonStyle()
            } else {
                Button(action: { showingAddBookmark = true }) {
                    Label(localization.localizedString("main.add.first"), systemImage: "plus")
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
            return localization.localizedString("main.empty.filtered.title")
        } else if showOnlyUnread {
            return localization.localizedString("main.empty.unread.title")
        } else {
            return localization.localizedString("main.empty.default.title")
        }
    }
    
    private var emptyStateMessage: String {
        if selectedCategory != nil {
            return localization.localizedString("main.empty.filtered.message")
        } else if showOnlyUnread {
            return localization.localizedString("main.empty.unread.message")
        } else {
            return localization.localizedString("main.empty.default.message")
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
            #if DEBUG
            print("⚠️ No user logged in, skipping Supabase fetch")
            #endif
            return
        }
        
        isLoadingFromSupabase = true
        defer { isLoadingFromSupabase = false }
        
        do {
            let supabaseBookmarks = try await SupabaseManager.shared.fetchBookmarks(userId: userId)
            #if DEBUG
            print("✅ Fetched \(supabaseBookmarks.count) bookmarks from Supabase")
            #endif
            
            // Sync to local SwiftData
            for dto in supabaseBookmarks {
                let bookmarkId = dto.id
                let fetchDescriptor = FetchDescriptor<Bookmark>(
                    predicate: #Predicate { $0.id == bookmarkId }
                )
                
                let existing = (try? modelContext.fetch(fetchDescriptor)) ?? []
                
                if existing.isEmpty {
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
            #if DEBUG
            print("✅ Synced bookmarks to local database")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load bookmarks from Supabase: \(error)")
            #endif
        }
    }
    
    // MARK: - Share Extension Integration
    
    private func loadPendingBookmarksFromShareExtension() {
        let defaults = UserDefaults(suiteName: "group.com.muartdev.mind")
        
        guard let pendingBookmarks = defaults?.array(forKey: "pendingBookmarks") as? [[String: Any]],
              !pendingBookmarks.isEmpty else {
            return
        }
        
        #if DEBUG
        print("📥 Found \(pendingBookmarks.count) pending bookmarks from Share Extension")
        #endif
        
        for bookmarkData in pendingBookmarks {
            guard let title = bookmarkData["title"] as? String,
                  let url = bookmarkData["url"] as? String,
                  let category = bookmarkData["category"] as? String else {
                continue
            }

            let dedupeKey = Bookmark.dedupeKey(url)
            if bookmarks.contains(where: { Bookmark.dedupeKey($0.url) == dedupeKey }) {
                continue
            }

            let thumbnailURL = bookmarkData["thumbnailURL"] as? String

            let bookmark = Bookmark(
                title: title,
                url: url,
                notes: "",
                category: category,
                dateAdded: Date(),
                isRead: false,
                thumbnailURL: thumbnailURL,
                tags: []
            )

            modelContext.insert(bookmark)

            // Fetch preview if thumbnail is missing
            if thumbnailURL == nil || thumbnailURL?.isEmpty == true {
                Task {
                    if let preview = try? await URLPreviewManager.shared.fetchPreview(for: url) {
                        await MainActor.run {
                            if let img = preview.imageURL, !img.isEmpty {
                                bookmark.thumbnailURL = img
                            }
                            if bookmark.title.isEmpty, let previewTitle = preview.title {
                                bookmark.title = previewTitle
                            }
                            try? modelContext.save()
                        }
                    }
                }
            }

            // Also save to Supabase
            if let userId = authManager.currentUser?.id {
                Task {
                    do {
                        try await SupabaseManager.shared.createBookmark(bookmark, userId: userId)
                        #if DEBUG
                        print("✅ Synced shared bookmark to Supabase: \(title)")
                        #endif
                    } catch {
                        #if DEBUG
                        print("❌ Failed to sync shared bookmark: \(error)")
                        #endif
                    }
                }
            }
        }
        
        // Clear pending bookmarks
        defaults?.removeObject(forKey: "pendingBookmarks")
        defaults?.synchronize()
        
        #if DEBUG
        print("✅ Imported \(pendingBookmarks.count) bookmarks from Share Extension")
        #endif

        syncSavedURLsToAppGroup()
    }

    /// Writes saved bookmark URLs and dates to shared UserDefaults so the Share Extension can detect duplicates.
    private func syncSavedURLsToAppGroup() {
        let defaults = UserDefaults(suiteName: "group.com.muartdev.mind")
        var urlMap: [String: Double] = [:]
        for bookmark in bookmarks {
            let key = Bookmark.dedupeKey(bookmark.url)
            urlMap[key] = bookmark.dateAdded.timeIntervalSince1970
        }
        defaults?.set(urlMap, forKey: "savedBookmarkURLs")
        defaults?.synchronize()
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: toggleViewMode) {
                Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                    .font(.headline)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { showingAddBookmark = true }) {
                Image(systemName: "plus")
                    .font(.headline)
            }
        }
    }
    
    private func toggleViewMode() {
        withAnimation(.smooth) {
            viewMode = viewMode == .list ? .grid : .list
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
