//
//  BookmarkDetailView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData
import UserNotifications

struct BookmarkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    @Environment(SupabaseManager.self) private var supabaseManager

    let bookmark: Bookmark
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedURL: String
    @State private var editedNotes: String
    @State private var editedCategory: Category
    @State private var editedTags: [String]
    @State private var newTag = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingReminderSheet = false
    @State private var reminderDate = Date()
    @State private var showingShareSheet = false
    
    init(bookmark: Bookmark) {
        self.bookmark = bookmark
        _editedTitle = State(initialValue: bookmark.title)
        _editedURL = State(initialValue: bookmark.url)
        _editedNotes = State(initialValue: bookmark.notes)
        _editedCategory = State(initialValue: Category.fromStoredValue(bookmark.category) ?? .general)
        _editedTags = State(initialValue: bookmark.tags)
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
            .navigationTitle(isEditing ? localization.localizedString("detail.edit") : localization.localizedString("detail.view"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingReminderSheet) {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            DatePicker(localization.localizedString("detail.select.time"), selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        Button(localization.localizedString("detail.set.reminder")) {
                            scheduleNotification()
                        }
                        .buttonStyle(PrimaryButtonStyle(theme: themeManager.currentTheme))
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                        .background(.ultraThinMaterial)
                    }
                    .navigationTitle(localization.localizedString("detail.set.reminder"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(localization.localizedString("common.cancel")) { showingReminderSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = URL(string: bookmark.url) {
                    ShareSheet(items: [bookmark.title, url])
                }
            }
            .confirmationDialog(
                localization.localizedString("detail.delete.confirm"),
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(localization.localizedString("common.delete"), role: .destructive) {
                    deleteBookmark()
                }
                Button(localization.localizedString("common.cancel"), role: .cancel) { }
            } message: {
                Text(localization.localizedString("detail.delete.message"))
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
                Text(localization.localizedString("detail.title"))
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
                Text(localization.localizedString("detail.url"))
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
                    Text(localization.localizedString("detail.notes"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(bookmark.notes)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .detailCardStyle()
            }
            
            // Tags
            if !bookmark.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.localizedString("detail.tags"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 8) {
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .detailCardStyle()
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(localization.localizedString("detail.added"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(bookmark.dateAdded, style: .date)
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text(localization.localizedString("detail.time"))
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
                title: localization.localizedString("detail.title"),
                icon: "text.quote",
                text: $editedTitle,
                placeholder: localization.localizedString("add.title.placeholder")
            )
            
            InputField(
                title: localization.localizedString("detail.url"),
                icon: "link",
                text: $editedURL,
                placeholder: "https://example.com"
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            
            InputField(
                title: localization.localizedString("detail.notes"),
                icon: "note.text",
                text: $editedNotes,
                placeholder: localization.localizedString("add.notes.placeholder"),
                axis: .vertical,
                lineLimit: 4
            )
            
            // Category selection
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    Text(localization.localizedString("add.category"))
                        .font(.headline)
                }
                
                categoryGridEdit
            }
            .padding()
            .detailCardStyle()

            // Tags
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "tag")
                        .foregroundStyle(.secondary)
                    Text(localization.localizedString("detail.tags"))
                        .font(.headline)
                }
                
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
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                if !editedTags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(editedTags, id: \.self) { tag in
                            TagView(tag: tag, onDelete: { removeTag(tag) })
                        }
                    }
                }
            }
            .padding()
            .detailCardStyle()
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedTag.isEmpty, !editedTags.contains(trimmedTag) else { return }
        editedTags.append(trimmedTag)
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        editedTags.removeAll { $0 == tag }
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
                title: bookmark.isRead ? localization.localizedString("detail.mark.unread") : localization.localizedString("detail.mark.read"),
                icon: bookmark.isRead ? "circle" : "checkmark.circle",
                color: .green,
                action: toggleRead
            )
            
            actionButton(
                title: localization.localizedString("detail.open.browser"),
                icon: "safari",
                color: .blue,
                action: openURL
            )
            
            actionButton(
                title: localization.localizedString("detail.share"),
                icon: "square.and.arrow.up",
                color: .orange,
                action: shareBookmark
            )
            
            actionButton(
                title: localization.localizedString("detail.set.reminder"),
                icon: "bell",
                color: .purple,
                action: { showingReminderSheet = true }
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
            if let category = Category.fromStoredValue(bookmark.category) {
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
            Button(isEditing ? localization.localizedString("common.cancel") : localization.localizedString("common.done")) {
                if isEditing {
                    cancelEditing()
                } else {
                    dismiss()
                }
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            if isEditing {
                Button(localization.localizedString("common.save")) {
                    saveChanges()
                }
                .bold()
            } else {
                Menu {
                    Button(action: { isEditing = true }) {
                        Label(localization.localizedString("detail.edit"), systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label(localization.localizedString("common.delete"), systemImage: "trash")
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
        }
        Task {
            do {
                try await supabaseManager.updateBookmark(bookmark)
            } catch {
                supabaseManager.lastSyncError = "Failed to sync read status"
            }
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
        showingShareSheet = true
    }
    
    private func scheduleNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                let content = UNMutableNotificationContent()
                content.title = "Read: \(bookmark.title)"
                content.body = bookmark.notes.isEmpty ? "Time to read your saved bookmark!" : bookmark.notes
                content.sound = .default
                
                let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                let request = UNNotificationRequest(identifier: bookmark.id.uuidString, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
                
                DispatchQueue.main.async {
                    showingReminderSheet = false
                }
            } else if let error = error {
                #if DEBUG
                print("Notification permission error: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    private func saveChanges() {
        bookmark.title = editedTitle
        bookmark.url = editedURL
        bookmark.notes = editedNotes
        bookmark.category = editedCategory.storageKey
        bookmark.tags = editedTags

        try? modelContext.save()

        Task {
            do {
                try await supabaseManager.updateBookmark(bookmark)
            } catch {
                supabaseManager.lastSyncError = "Failed to sync bookmark changes"
            }
        }

        withAnimation(.smooth) {
            isEditing = false
        }
    }
    
    private func cancelEditing() {
        editedTitle = bookmark.title
        editedURL = bookmark.url
        editedNotes = bookmark.notes
        editedCategory = Category.fromStoredValue(bookmark.category) ?? .general
        editedTags = bookmark.tags
        
        withAnimation(.smooth) {
            isEditing = false
        }
    }
    
    private func deleteBookmark() {
        modelContext.delete(bookmark)
        Task {
            do {
                try await supabaseManager.deleteBookmark(id: bookmark.id)
            } catch {
                supabaseManager.lastSyncError = "Failed to delete bookmark from cloud"
            }
        }
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
                    .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .primary.opacity(0.08), radius: 12, x: 0, y: 6)
            .shadow(color: .primary.opacity(0.04), radius: 4, x: 0, y: 2)
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
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .primary.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Bookmark.self, configurations: config)
    let bookmark = Bookmark.samples[0]
    container.mainContext.insert(bookmark)
    
    return BookmarkDetailView(bookmark: bookmark)
        .modelContainer(container)
        .environment(ThemeManager())
        .environment(LocalizationManager.shared)
}
