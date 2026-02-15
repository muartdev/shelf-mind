//
//  AddBookmarkView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData

struct AddBookmarkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AuthManager.self) private var authManager
    @Environment(LocalizationManager.self) private var localization
    @Environment(SupabaseManager.self) private var supabaseManager

    @Query private var bookmarks: [Bookmark]
    
    @State private var title = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var selectedCategory = Category.general
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    @State private var isSaving = false
    @State private var showingPaywall = false
    @State private var isLoadingPreview = false
    @State private var previewTitle: String?
    @State private var previewImage: String?
    @State private var thumbnailURL: String?
    @State private var previewTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - themed
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        formSection
                        categorySection
                        tagsSection
                    }
                    .padding()
                }
            }
            .navigationTitle(localization.localizedString("add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // URL field (first - most important)
            VStack(alignment: .leading, spacing: 8) {
                Label(localization.localizedString("add.url"), systemImage: "link.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                
                HStack(spacing: 12) {
                    TextField(localization.localizedString("add.url.placeholder"), text: $url)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .font(.body)
                        .onChange(of: url) { oldValue, newValue in
                            if newValue != oldValue && !newValue.isEmpty {
                                if PaywallManager.shared.canUseURLPreview(currentCount: bookmarks.count) {
                                    loadURLPreview(for: newValue)
                                }
                                // Don't interrupt - the premium upsell card below handles the CTA
                            }
                        }
                    
                    if isLoadingPreview {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    themeManager.currentTheme.primaryColor.opacity(0.3),
                                    themeManager.currentTheme.secondaryColor.opacity(0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                )
            }
            
            // Preview Card (if available) or Premium upsell
            if previewTitle != nil {
                previewCard
            } else if !url.isEmpty && !PaywallManager.shared.canUseURLPreview(currentCount: bookmarks.count) {
                Button(action: { showingPaywall = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(.yellow)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.localizedString("preview.premium.title"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(localization.localizedString("preview.premium.desc"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(
                        LinearGradient(
                            colors: [.yellow.opacity(0.1), .orange.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.yellow.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Title field
            VStack(alignment: .leading, spacing: 8) {
                Label(localization.localizedString("add.title.field"), systemImage: "text.quote")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                TextField(localization.localizedString("add.title.placeholder"), text: $title)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                    )
            }
            
            // Notes field (collapsible)
            VStack(alignment: .leading, spacing: 8) {
                Label(localization.localizedString("add.notes"), systemImage: "note.text")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                TextField(localization.localizedString("add.notes.placeholder"), text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .lineLimit(3...5)
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                    )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .primary.opacity(0.08), radius: 20, y: 10)
    }
    
    // MARK: - Preview Card
    
    private var previewCard: some View {
        Button(action: {
            if let previewTitle = previewTitle {
                title = previewTitle
                thumbnailURL = previewImage
            }
        }) {
            HStack(spacing: 12) {
                if let previewImage = previewImage {
                    AsyncImage(url: URL(string: previewImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeManager.currentTheme.primaryColor.opacity(0.3),
                                        themeManager.currentTheme.secondaryColor.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay {
                                ProgressView()
                                    .tint(.secondary)
                            }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let previewTitle = previewTitle {
                        Text(previewTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text(localization.localizedString("add.preview.tap"))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                themeManager.currentTheme.primaryColor,
                                themeManager.currentTheme.secondaryColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.primaryColor.opacity(0.1),
                        themeManager.currentTheme.secondaryColor.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                themeManager.currentTheme.primaryColor.opacity(0.5),
                                themeManager.currentTheme.secondaryColor.opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.2), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                Text(localization.localizedString("add.category"))
                    .font(.headline)
            }

            Menu {
                ForEach(Category.allCases) { category in
                    Button(action: { selectedCategory = category }) {
                        Label(category.rawValue, systemImage: category.icon)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedCategory.icon)
                        .foregroundStyle(selectedCategory.color)
                        .font(.body)
                    Text(selectedCategory.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .formGlassStyle()
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                Text(localization.localizedString("detail.tags"))
                    .font(.headline)
            }
            
            // Tag input
            HStack(spacing: 12) {
                TextField(localization.localizedString("detail.add.tag"), text: $newTag)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .onSubmit(addTag)
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            )
            
            // Tags list
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagView(tag: tag, onDelete: {
                            removeTag(tag)
                        })
                    }
                }
            }
        }
        .padding(20)
        .formGlassStyle()
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else { return }
        tags.append(trimmedTag)
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Text(localization.localizedString("add.cancel"))
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button {
                saveBookmark()
            } label: {
                Text(localization.localizedString("add.save"))
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveBookmark() {
        // Check premium limit
        if !PaywallManager.shared.canAddBookmark(currentCount: bookmarks.count) {
            showingPaywall = true
            return
        }
        
        // Validation
        guard !title.isEmpty else {
            validationMessage = localization.localizedString("add.error.title")
            showingValidationError = true
            return
        }
        
        guard !url.isEmpty else {
            validationMessage = localization.localizedString("add.error.url")
            showingValidationError = true
            return
        }
        
        guard let parsedURL = URL(string: url), let scheme = parsedURL.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else {
            validationMessage = localization.localizedString("add.error.url.invalid")
            showingValidationError = true
            return
        }

        if let existing = bookmarks.findDuplicate(of: url) {
            let dateStr = existing.dateAdded.relativeDisplayString(
                language: localization.currentLanguage.code
            )
            validationMessage = String(
                format: localization.localizedString("add.error.duplicate_with_date"),
                dateStr
            )
            showingValidationError = true
            return
        }
        
        let bookmark = Bookmark(
            title: title,
            url: url,
            notes: notes,
            category: selectedCategory.storageKey,
            dateAdded: Date(),
            isRead: false,
            thumbnailURL: thumbnailURL,
            tags: tags
        )
        
        // Save to local SwiftData
        modelContext.insert(bookmark)
        HapticManager.notification(.success)
        
        // Save to Supabase
        Task {
            isSaving = true
            defer { isSaving = false }
            
            guard let userId = authManager.currentUser?.id else {
                #if DEBUG
                print("❌ No user ID found")
                #endif
                return
            }
            
            do {
                try await supabaseManager.createBookmark(bookmark, userId: userId)
                #if DEBUG
                print("✅ Bookmark saved to Supabase")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to save bookmark to Supabase: \(error)")
                #endif
                // Still saved locally; queued for sync if possible
            }
        }
        
        dismiss()
    }
    
    // MARK: - URL Preview
    
    private static let allowedSchemes: Set<String> = ["http", "https"]

    private func loadURLPreview(for urlString: String) {
        previewTask?.cancel()

        // Only fetch previews for safe URLs
        guard let parsed = URL(string: urlString),
              let scheme = parsed.scheme?.lowercased(),
              Self.allowedSchemes.contains(scheme) else { return }

        // Debounce - wait a bit for user to finish typing
        previewTask = Task {
            try? await Task.sleep(for: .seconds(0.5))
            
            guard !Task.isCancelled else { return }
            guard self.url == urlString else { return } // User changed URL
            
            await MainActor.run {
                isLoadingPreview = true
            }
            defer {
                Task { @MainActor in
                    isLoadingPreview = false
                }
            }
            
            do {
                let preview = try await URLPreviewManager.shared.fetchPreview(for: urlString)
                
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.previewTitle = preview.title
                    self.previewImage = preview.imageURL
                    
                    // Auto-fill title if empty
                    if self.title.isEmpty, let title = preview.title {
                        self.title = title
                    }
                    
                    // Auto-select category
                    if let category = URLPreviewManager.shared.suggestCategory(for: urlString) {
                        self.selectedCategory = category
                    }
                    
                    // Auto-save thumbnail
                    self.thumbnailURL = preview.imageURL
                }
            } catch {
                #if DEBUG
                print("❌ Failed to load preview: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

// MARK: - Input Field Component

struct InputField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let placeholder: String
    var axis: Axis = .horizontal
    var lineLimit: Int = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
            }
            
            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.plain)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .lineLimit(lineLimit)
        }
    }
}

// MARK: - Category Button Component

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.smooth) {
                action()
            }
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(category.color.gradient)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: category.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                
                Text(category.shortName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(category.color)
                        .font(.body)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .frame(height: 100)
        .categoryButtonStyle(isSelected: isSelected, color: category.color)
    }
}

// MARK: - Style Extensions

extension View {
    @ViewBuilder
    func formGlassStyle() -> some View {
        self
            .padding()
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .primary.opacity(0.08), radius: 15, x: 0, y: 8)
            .shadow(color: .primary.opacity(0.04), radius: 5, x: 0, y: 2)
    }
    
    @ViewBuilder
    func categoryButtonStyle(isSelected: Bool, color: Color) -> some View {
        self
            .background(
                isSelected ? color.opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .background(
                .thinMaterial,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? color.opacity(0.5) : .primary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? color.opacity(0.2) : .clear, radius: 8, y: 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Bookmark.self, configurations: config)
    
    return AddBookmarkView()
        .modelContainer(container)
        .environment(ThemeManager())
}
