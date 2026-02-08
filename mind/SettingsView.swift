//
//  SettingsView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [Bookmark]
    
    @State private var notificationsEnabled = true
    @State private var reminderTime = Date()
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var exportedData: Data?
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    if let user = authManager.currentUser {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Text(user.name.prefix(1).uppercased())
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Appearance Section
                Section("Appearance") {
                    ForEach(AppTheme.allCases) { theme in
                        Button(action: {
                            withAnimation(.smooth) {
                                themeManager.currentTheme = theme
                            }
                        }) {
                            HStack(spacing: 16) {
                                // Theme preview
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.previewGradient)
                                    .frame(width: 50, height: 50)
                                    .overlay {
                                        Image(systemName: theme.icon)
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                    }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(theme.displayName)
                                        .foregroundStyle(.primary)
                                    Text(theme.isDark ? "Dark Mode" : "Light Mode")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Notifications
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        DatePicker("Daily Reminder", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                // Data Management
                Section("Data") {
                    Button(action: { showingExportSheet = true }) {
                        Label("Export Bookmarks", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { showingImportSheet = true }) {
                        Label("Import Bookmarks", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete All Bookmarks", systemImage: "trash")
                    }
                }
                
                // Statistics
                Section("Statistics") {
                    HStack {
                        Text("Total Bookmarks")
                        Spacer()
                        Text("\(bookmarks.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Unread")
                        Spacer()
                        Text("\(bookmarks.filter { !$0.isRead }.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("GitHub", systemImage: "link")
                    }
                }
                
                // Account
                Section {
                    Button(role: .destructive, action: signOut) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingExportSheet) {
                ExportView(bookmarks: bookmarks)
            }
            .confirmationDialog("Delete All Bookmarks", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    deleteAllBookmarks()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All your bookmarks will be permanently deleted.")
            }
        }
    }
    
    private func signOut() {
        authManager.signOut()
    }
    
    private func deleteAllBookmarks() {
        for bookmark in bookmarks {
            modelContext.delete(bookmark)
        }
    }
}

// MARK: - Export View

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    let bookmarks: [Bookmark]
    @State private var exportedData: Data?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                Text("Export Bookmarks")
                    .font(.title2)
                    .bold()
                
                Text("Export all your bookmarks as JSON file")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    InfoRow(label: "Total Bookmarks", value: "\(bookmarks.count)")
                    InfoRow(label: "Unread", value: "\(bookmarks.filter { !$0.isRead }.count)")
                    InfoRow(label: "Categories", value: "\(Set(bookmarks.map { $0.category }).count)")
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                Button(action: exportBookmarks) {
                    Label("Export Now", systemImage: "square.and.arrow.up")
                        .font(.headline)
                }
                .buttonStyle(PrimaryButtonStyle(theme: themeManager.currentTheme))
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = exportedData {
                    ShareSheet(items: [data])
                }
            }
        }
    }
    
    private func exportBookmarks() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let exportData = bookmarks.map { bookmark in
            [
                "id": bookmark.id.uuidString,
                "title": bookmark.title,
                "url": bookmark.url,
                "notes": bookmark.notes,
                "category": bookmark.category,
                "dateAdded": ISO8601DateFormatter().string(from: bookmark.dateAdded),
                "isRead": bookmark.isRead ? "true" : "false",
                "tags": bookmark.tags.joined(separator: ",")
            ]
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) {
            exportedData = data
            showingShareSheet = true
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .bold()
        }
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
    let authManager = AuthManager()
    authManager.currentUser = User.sample
    authManager.isAuthenticated = true
    
    return SettingsView()
        .environment(authManager)
        .environment(ThemeManager())
}
