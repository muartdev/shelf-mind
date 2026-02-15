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
    @Environment(SupabaseManager.self) private var supabaseManager
    @Query(sort: \Bookmark.dateAdded, order: .reverse) private var bookmarks: [Bookmark]
    
    @State private var showingAddBookmark = false
    @State private var selectedBookmark: Bookmark?
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showOnlyUnread = false
    @State private var isLoadingFromSupabase = false
    @State private var viewMode: ViewMode = .list
    @State private var displayLimit = 20
    private let pageSize = 20
    
    enum ViewMode {
        case list
        case grid
    }
    
    var filteredBookmarks: [Bookmark] {
        let search = searchText
        let category = selectedCategory
        let unreadOnly = showOnlyUnread

        // Single-pass filter for better performance
        return bookmarks.filter { bookmark in
            if let category, bookmark.category != category {
                return false
            }
            if unreadOnly && bookmark.isRead {
                return false
            }
            if !search.isEmpty {
                let matchesSearch = bookmark.title.localizedStandardContains(search) ||
                    bookmark.notes.localizedStandardContains(search) ||
                    bookmark.url.localizedStandardContains(search)
                if !matchesSearch { return false }
            }
            return true
        }
    }

    var paginatedBookmarks: [Bookmark] {
        Array(filteredBookmarks.prefix(displayLimit))
    }

    var hasMore: Bool {
        displayLimit < filteredBookmarks.count
    }

    var unreadCount: Int {
        bookmarks.lazy.filter { !$0.isRead }.count
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
            .overlay(alignment: .bottom) {
                if let error = supabaseManager.lastSyncError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.icloud")
                        Text(error)
                            .font(.caption)
                        Spacer()
                        Button {
                            supabaseManager.lastSyncError = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        // Auto-dismiss after 4 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation { supabaseManager.lastSyncError = nil }
                        }
                    }
                }
            }
            .animation(.smooth, value: supabaseManager.lastSyncError)
        }
    }
    
    // MARK: - Subviews
    
    private var bookmarkListView: some View {
        VStack(spacing: 0) {
                    // Sticky Filter Header - minimal
            filterChipsView
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                .zIndex(1)
            
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
            ForEach(paginatedBookmarks) { bookmark in
                BookmarkCard(bookmark: bookmark)
                    .onTapGesture {
                        selectedBookmark = bookmark
                    }
            }
            loadMoreButton
        }
    }
    
    private var gridLayout: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(paginatedBookmarks) { bookmark in
                    BookmarkCard(bookmark: bookmark, isCompact: true, onTap: {
                        selectedBookmark = bookmark
                    })
                }
            }
            loadMoreButton
        }
    }

    @ViewBuilder
    private var loadMoreButton: some View {
        if hasMore {
            Button {
                withAnimation { displayLimit += pageSize }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle")
                    Text(localization.localizedString("main.load.more"))
                }
                .font(.subheadline)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
    
    private func refreshBookmarks() async {
        await loadBookmarksFromSupabase()
        loadPendingBookmarksFromShareExtension()
    }
    
    @ViewBuilder
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: localization.localizedString("main.filter.all"),
                    isSelected: selectedCategory == nil && !showOnlyUnread,
                    accentColor: themeManager.currentTheme.primaryColor,
                    action: {
                        selectedCategory = nil
                        showOnlyUnread = false
                    }
                )
                
                ForEach(Category.allCases) { category in
                    let count = bookmarks.filter { $0.category == category.storageKey }.count
                    FilterChip(
                        title: category.shortName,
                        count: count > 0 ? count : nil,
                        isSelected: selectedCategory == category.storageKey,
                        accentColor: category.color,
                        action: {
                            selectedCategory = selectedCategory == category.storageKey ? nil : category.storageKey
                        }
                    )
                }
                
                FilterChip(
                    title: localization.localizedString("main.filter.unread"),
                    count: unreadCount > 0 ? unreadCount : nil,
                    isSelected: showOnlyUnread,
                    accentColor: .orange,
                    action: { showOnlyUnread.toggle() }
                )
            }
            .padding(.horizontal, 4)
        }
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
        displayLimit = pageSize
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
            let supabaseBookmarks = try await supabaseManager.fetchBookmarks(userId: userId)
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

            if bookmarks.containsDuplicate(of: url) {
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
                        try await supabaseManager.createBookmark(bookmark, userId: userId)
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

// MARK: - Filter Chip Component (Minimal)

struct FilterChip: View {
    let title: String
    var count: Int?
    let isSelected: Bool
    var accentColor: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.smooth(duration: 0.2)) {
                action()
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if let count, count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? accentColor : .secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(accentColor.opacity(0.12))
                }
            }
            .foregroundStyle(isSelected ? accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Extension for Styles

extension View {
    @ViewBuilder
    func glassButtonStyle() -> some View {
        self.buttonStyle(.borderedProminent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Bookmark.self, inMemory: true)
        .environment(ThemeManager())
}
