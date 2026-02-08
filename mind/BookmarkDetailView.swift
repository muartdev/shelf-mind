//
//  BookmarkDetailView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData

struct BookmarkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    
    let bookmark: Bookmark
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedURL: String
    @State private var editedNotes: String
    @State private var editedCategory: Category
    @State private var showingDeleteConfirmation = false
    
    init(bookmark: Bookmark) {
        self.bookmark = bookmark
        _editedTitle = State(initialValue: bookmark.title)
        _editedURL = State(initialValue: bookmark.url)
        _editedNotes = State(initialValue: bookmark.notes)
        _editedCategory = State(initialValue: Category.allCases.first(where: { $0.rawValue.lowercased() == bookmark.category }) ?? .general)
    }
    
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
                        if isEditing {
                            editingView
                        } else {
                            detailView
                        }
                        
                        actionButtonsSection
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Bookmark" : "Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .confirmationDialog(
                "Delete Bookmark",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteBookmark()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this bookmark? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Detail View (Read Mode)
    
    private var detailView: some View {
        VStack(spacing: 24) {
            // Status and Category
            HStack {
                statusBadge
                Spacer()
                categoryBadge
            }
            
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(bookmark.title)
                    .font(.title2)
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .detailCardStyle()
            
            // URL
            VStack(alignment: .leading, spacing: 8) {
                Text("URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(bookmark.url)
                    .font(.body)
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .detailCardStyle()
            
            // Notes
            if !bookmark.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(bookmark.notes)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .detailCardStyle()
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("Added")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(bookmark.dateAdded, style: .date)
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(bookmark.dateAdded, style: .time)
                        .font(.caption)
                }
            }
            .padding()
            .detailCardStyle()
        }
    }
    
    // MARK: - Editing View
    
    private var editingView: some View {
        VStack(spacing: 16) {
            InputField(
                title: "Title",
                icon: "text.quote",
                text: $editedTitle,
                placeholder: "Enter bookmark title"
            )
            
            InputField(
                title: "URL",
                icon: "link",
                text: $editedURL,
                placeholder: "https://example.com"
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            
            InputField(
                title: "Notes",
                icon: "note.text",
                text: $editedNotes,
                placeholder: "Add notes (optional)",
                axis: .vertical,
                lineLimit: 4
            )
            
            // Category selection
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    Text("Category")
                        .font(.headline)
                }
                
                categoryGridEdit
            }
            .padding()
            .detailCardStyle()
        }
    }
    
    @ViewBuilder
    private var categoryGridEdit: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
            ForEach(Category.allCases) { category in
                CategoryButton(
                    category: category,
                    isSelected: editedCategory == category,
                    action: { editedCategory = category }
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            actionButton(
                title: bookmark.isRead ? "Mark as Unread" : "Mark as Read",
                icon: bookmark.isRead ? "circle" : "checkmark.circle",
                color: .green,
                action: toggleRead
            )
            
            actionButton(
                title: "Open in Browser",
                icon: "safari",
                color: .blue,
                action: openURL
            )
            
            actionButton(
                title: "Share",
                icon: "square.and.arrow.up",
                color: .orange,
                action: shareBookmark
            )
        }
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .font(.headline)
            .padding()
        }
        .foregroundStyle(color)
        .actionButtonStyle()
    }
    
    // MARK: - Badges
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: bookmark.isRead ? "checkmark.circle.fill" : "circle.badge")
            Text(bookmark.isRead ? "Read" : "Unread")
                .font(.caption)
                .bold()
        }
        .foregroundStyle(bookmark.isRead ? .green : .blue)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    private var categoryBadge: some View {
        HStack(spacing: 6) {
            if let category = Category.allCases.first(where: { $0.rawValue.lowercased() == bookmark.category }) {
                Image(systemName: category.icon)
                Text(category.rawValue)
                    .font(.caption)
                    .bold()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(isEditing ? "Cancel" : "Done") {
                if isEditing {
                    cancelEditing()
                } else {
                    dismiss()
                }
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            if isEditing {
                Button("Save") {
                    saveChanges()
                }
                .bold()
            } else {
                Menu {
                    Button(action: { isEditing = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleRead() {
        withAnimation(.smooth) {
            bookmark.isRead.toggle()
            dismiss()
        }
    }
    
    private func openURL() {
        if let url = URL(string: bookmark.url) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
    
    private func shareBookmark() {
        guard let url = URL(string: bookmark.url) else { return }
        
        #if os(iOS)
        let activityVC = UIActivityViewController(
            activityItems: [bookmark.title, url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
    
    private func saveChanges() {
        bookmark.title = editedTitle
        bookmark.url = editedURL
        bookmark.notes = editedNotes
        bookmark.category = editedCategory.rawValue.lowercased()
        
        withAnimation(.smooth) {
            isEditing = false
        }
    }
    
    private func cancelEditing() {
        editedTitle = bookmark.title
        editedURL = bookmark.url
        editedNotes = bookmark.notes
        editedCategory = Category.allCases.first(where: { $0.rawValue.lowercased() == bookmark.category }) ?? .general
        
        withAnimation(.smooth) {
            isEditing = false
        }
    }
    
    private func deleteBookmark() {
        modelContext.delete(bookmark)
        dismiss()
    }
}

// MARK: - Style Extensions

extension View {
    @ViewBuilder
    func detailCardStyle() -> some View {
        self
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    func actionButtonStyle() -> some View {
        self
            .background(
                .thinMaterial,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Bookmark.self, configurations: config)
    let bookmark = Bookmark.samples[0]
    container.mainContext.insert(bookmark)
    
    return BookmarkDetailView(bookmark: bookmark)
        .modelContainer(container)
        .environment(ThemeManager())
}
