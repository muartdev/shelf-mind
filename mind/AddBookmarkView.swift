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
    
    @State private var title = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var selectedCategory = Category.general
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
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
            .navigationTitle("Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title field
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "text.quote")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                    Text("Title")
                        .font(.headline)
                }
                
                TextField("Enter bookmark title", text: $title)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            // URL field
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                    Text("URL")
                        .font(.headline)
                }
                
                TextField("https://example.com", text: $url)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            // Notes field
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                    Text("Notes")
                        .font(.headline)
                }
                
                TextField("Add notes (optional)", text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(4...6)
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .padding(20)
        .formGlassStyle()
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                Text("Category")
                    .font(.headline)
            }
            
            categoryGrid
        }
        .padding(20)
        .formGlassStyle()
    }
    
    @ViewBuilder
    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Category.allCases) { category in
                CategoryButton(
                    category: category,
                    isSelected: selectedCategory == category,
                    action: { selectedCategory = category }
                )
            }
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                Text("Tags")
                    .font(.headline)
            }
            
            // Tag input
            HStack(spacing: 12) {
                TextField("Add tag", text: $newTag)
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
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
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
                Text("Cancel")
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button {
                saveBookmark()
            } label: {
                Text("Save")
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveBookmark() {
        // Validation
        guard !title.isEmpty else {
            validationMessage = "Please enter a title"
            showingValidationError = true
            return
        }
        
        guard !url.isEmpty else {
            validationMessage = "Please enter a URL"
            showingValidationError = true
            return
        }
        
        guard URL(string: url) != nil else {
            validationMessage = "Please enter a valid URL"
            showingValidationError = true
            return
        }
        
        let bookmark = Bookmark(
            title: title,
            url: url,
            notes: notes,
            category: selectedCategory.rawValue.lowercased(),
            tags: tags
        )
        
        modelContext.insert(bookmark)
        dismiss()
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
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
                    .strokeBorder(isSelected ? color.opacity(0.5) : .white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
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
