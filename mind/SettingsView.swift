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
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Section
                        if let user = authManager.currentUser {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 60, height: 60)
                                    .overlay {
                                        Text(user.name.prefix(1).uppercased())
                                            .font(.title)
                                            .foregroundStyle(.white)
                                    }
                                    .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 8, y: 4)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .settingsCardStyle()
                        }
                        
                        // Appearance Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Appearance")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(AppTheme.allCases) { theme in
                                        ThemeCard(
                                            theme: theme,
                                            isSelected: themeManager.currentTheme == theme,
                                            action: {
                                                withAnimation(.smooth) {
                                                    themeManager.currentTheme = theme
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Notifications
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notifications")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                            
                            if notificationsEnabled {
                                DatePicker("Daily Reminder", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            }
                        }
                        .padding()
                        .settingsCardStyle()
                        
                        // Data Management
                        VStack(spacing: 0) {
                            Text("Data")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                            
                            VStack(spacing: 0) {
                                Button(action: { showingExportSheet = true }) {
                                    HStack {
                                        Label("Export Bookmarks", systemImage: "square.and.arrow.up")
                                        Spacer()
                                    }
                                    .foregroundStyle(.primary)
                                    .padding()
                                }
                                
                                Divider()
                                    .padding(.leading)
                                
                                Button(action: { showingImportSheet = true }) {
                                    HStack {
                                        Label("Import Bookmarks", systemImage: "square.and.arrow.down")
                                        Spacer()
                                    }
                                    .foregroundStyle(.primary)
                                    .padding()
                                }
                                
                                Divider()
                                    .padding(.leading)
                                
                                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                                    HStack {
                                        Label("Delete All Bookmarks", systemImage: "trash")
                                        Spacer()
                                    }
                                    .padding()
                                }
                            }
                            .settingsCardStyle()
                        }
                        
                        // Statistics
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Statistics")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Text("Total Bookmarks")
                                Spacer()
                                Text("\(bookmarks.count)")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Unread")
                                Spacer()
                                Text("\(bookmarks.filter { !$0.isRead }.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .settingsCardStyle()
                        
                        // About
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Divider()
                            
                            Link(destination: URL(string: "https://github.com/muartdev/shelf-mind")!) {
                                HStack {
                                    Label("GitHub", systemImage: "link")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .settingsCardStyle()
                        
                        // Sign Out
                        Button(role: .destructive, action: signOut) {
                            Text("Sign Out")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .settingsCardStyle()
                    }
                    .padding()
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

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Theme preview circle
                Circle()
                    .fill(theme.previewGradient)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: theme.icon)
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        if isSelected {
                            Circle()
                                .strokeBorder(.white, lineWidth: 3)
                            Circle()
                                .strokeBorder(theme.primaryColor, lineWidth: 6)
                                .padding(-3)
                        }
                    }
                
                VStack(spacing: 2) {
                    Text(theme.displayName)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                    Text(theme.isDark ? "Dark" : "Light")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Card Style

extension View {
    func settingsCardStyle() -> some View {
        self
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    let authManager = AuthManager()
    authManager.currentUser = User.sample
    authManager.isAuthenticated = true
    
    return SettingsView()
        .environment(authManager)
        .environment(ThemeManager())
}
