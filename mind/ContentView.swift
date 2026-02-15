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
    @State private var showOnlyFavorites = false
    @State private var isLoadingFromSupabase = false
    @State private var viewMode: ViewMode = .list
    @State private var displayLimit = 20
    @State private var sortOption: SortOption = .dateNewest
    private let pageSize = 20
    
    enum ViewMode {
        case list
        case grid
    }
    
    enum SortOption: String, CaseIterable {
        case dateNewest = "sort.date.newest"
        case dateOldest = "sort.date.oldest"
        case titleAZ = "sort.title.az"
        case titleZA = "sort.title.za"
        case category = "sort.category"
        case readFirst = "sort.read.first"
        case unreadFirst = "sort.unread.first"
    }
    
    var filteredBookmarks: [Bookmark] {
        let search = searchText
        let category = selectedCategory
        let unreadOnly = showOnlyUnread
        let favoritesOnly = showOnlyFavorites

        var result = bookmarks.filter { bookmark in
            if let cat = category {
                let bookmarkStorageKey = (Category.fromStoredValue(bookmark.category) ?? .general).storageKey
                if bookmarkStorageKey != cat { return false }
            }
            if unreadOnly && bookmark.isRead {
                return false
            }
            if favoritesOnly && !bookmark.isFavorite {
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
        
        switch sortOption {
        case .dateNewest:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .dateOldest:
            result.sort { $0.dateAdded < $1.dateAdded }
        case .titleAZ:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .titleZA:
            result.sort { $0.title.localizedCompare($1.title) == .orderedDescending }
        case .category:
            result.sort { $0.category.localizedCompare($1.category) == .orderedAscending }
        case .readFirst:
            result.sort { $0.isRead && !$1.isRead }
        case .unreadFirst:
            result.sort { !$0.isRead && $1.isRead }
        }
        
        return result
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
    
    var favoritesCount: Int {
        bookmarks.lazy.filter { $0.isFavorite }.count
    }

    private var widgetDataSignature: String {
        bookmarks.map { "\($0.id)-\($0.isRead)" }.joined(separator: "|")
    }

    private func refreshWidgetData() {
        let unread = bookmarks.filter { !$0.isRead }.count
        let recent = bookmarks.prefix(5).map(\.title)
        WidgetDataManager.update(unreadCount: unread, totalCount: bookmarks.count, recentTitles: recent)
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
                        icon: selectedCategory != nil || showOnlyUnread || showOnlyFavorites ? "tray" : "bookmark.slash",
                        title: emptyStateTitle,
                        message: emptyStateMessage,
                        buttonTitle: selectedCategory != nil || showOnlyUnread || showOnlyFavorites ? localization.localizedString("main.clear.filters") : localization.localizedString("main.add.first"),
                        action: {
                            if selectedCategory != nil || showOnlyUnread || showOnlyFavorites {
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
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear { refreshWidgetData() }
            .onChange(of: widgetDataSignature) { _, _ in refreshWidgetData() }
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

            if viewMode == .list {
                // List has its own scroll - do NOT nest inside ScrollView
                listLayout
                    .refreshable { await refreshBookmarks() }
            } else {
                ScrollView {
                    gridLayout
                        .padding()
                        .padding(.top, 4)
                }
                .scrollIndicators(.hidden)
                .refreshable { await refreshBookmarks() }
            }
        }
    }
    
    private var listLayout: some View {
        VStack(spacing: 0) {
            List {
                ForEach(paginatedBookmarks) { bookmark in
                    BookmarkCard(bookmark: bookmark, onTap: {
                            selectedBookmark = bookmark
                        })
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                deleteBookmark(bookmark)
                            } label: {
                                Label(localization.localizedString("common.delete"), systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                HapticManager.impact(.light)
                                toggleRead(bookmark)
                            } label: {
                                Label(
                                    bookmark.isRead ? localization.localizedString("common.mark.unread") : localization.localizedString("common.mark.read"),
                                    systemImage: bookmark.isRead ? "circle" : "checkmark.circle"
                                )
                            }
                            .tint(.green)
                        }
                }
                if hasMore {
                    loadMoreRow
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var loadMoreRow: some View {
        Button {
            withAnimation { displayLimit += pageSize }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.circle")
                Text(localization.localizedString("main.load.more"))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    private func deleteBookmark(_ bookmark: Bookmark) {
        withAnimation(.smooth) {
            modelContext.delete(bookmark)
        }
        Task {
            do {
                try await supabaseManager.deleteBookmark(id: bookmark.id)
            } catch {
                supabaseManager.lastSyncError = localization.localizedString("error.sync.delete")
            }
        }
    }
    
    private func toggleRead(_ bookmark: Bookmark) {
        withAnimation(.smooth) {
            bookmark.isRead.toggle()
        }
        Task {
            do {
                try await supabaseManager.updateBookmark(bookmark)
            } catch {
                supabaseManager.lastSyncError = localization.localizedString("error.sync.update")
            }
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
                    isSelected: selectedCategory == nil && !showOnlyUnread && !showOnlyFavorites,
                    accentColor: themeManager.currentTheme.primaryColor,
                    action: {
                        selectedCategory = nil
                        showOnlyUnread = false
                        showOnlyFavorites = false
                    }
                )
                
                ForEach(Category.allCases) { category in
                    let count = bookmarks.filter { (Category.fromStoredValue($0.category) ?? .general).storageKey == category.storageKey }.count
                    FilterChip(
                        title: category.filterDisplayName,
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
                
                FilterChip(
                    title: localization.localizedString("main.filter.favorites"),
                    count: favoritesCount > 0 ? favoritesCount : nil,
                    isSelected: showOnlyFavorites,
                    accentColor: .yellow,
                    action: { showOnlyFavorites.toggle() }
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
            
            if selectedCategory != nil || showOnlyUnread || showOnlyFavorites {
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
        } else if showOnlyFavorites {
            return localization.localizedString("main.empty.favorites.title")
        } else {
            return localization.localizedString("main.empty.default.title")
        }
    }
    
    private var emptyStateMessage: String {
        if selectedCategory != nil {
            return localization.localizedString("main.empty.filtered.message")
        } else if showOnlyUnread {
            return localization.localizedString("main.empty.unread.message")
        } else if showOnlyFavorites {
            return localization.localizedString("main.empty.favorites.message")
        } else {
            return localization.localizedString("main.empty.default.message")
        }
    }
    
    private func clearFilters() {
        selectedCategory = nil
        showOnlyUnread = false
        showOnlyFavorites = false
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
                        isFavorite: dto.is_favorite,
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
            HStack(spacing: 16) {
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            HapticManager.selection()
                            sortOption = option
                        } label: {
                            HStack {
                                Text(localization.localizedString(option.rawValue))
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.headline)
                }
                
                Button(action: {
                    HapticManager.impact(.light)
                    showingAddBookmark = true
                }) {
                    Image(systemName: "plus")
                        .font(.headline)
                }
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
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                if let count, count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(isSelected ? .white : accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? accentColor.opacity(0.6) : accentColor.opacity(0.15))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(accentColor.opacity(0.15))
                        .background(.ultraThinMaterial, in: Capsule())
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                        )
                }
            }
            .foregroundStyle(isSelected ? accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Extension for Styles

extension View {
    @ViewBuilder
    func glassButtonStyle() -> some View {
        self
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Bookmark.self, inMemory: true)
        .environment(ThemeManager())
}
