//
//  StatisticsView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var bookmarks: [Bookmark]
    @Environment(ThemeManager.self) private var themeManager
    
    var totalBookmarks: Int { bookmarks.count }
    var readBookmarks: Int { bookmarks.filter { $0.isRead }.count }
    var unreadBookmarks: Int { bookmarks.filter { !$0.isRead }.count }
    var readPercentage: Double {
        guard totalBookmarks > 0 else { return 0 }
        return Double(readBookmarks) / Double(totalBookmarks) * 100
    }
    
    var categoryStats: [CategoryStat] {
        Dictionary(grouping: bookmarks, by: { $0.category })
            .map { CategoryStat(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    var recentActivity: [ActivityData] {
        let calendar = Calendar.current
        let last7Days = (0..<7).map { calendar.date(byAdding: .day, value: -$0, to: Date())! }
        
        return last7Days.reversed().map { date in
            let count = bookmarks.filter { bookmark in
                calendar.isDate(bookmark.dateAdded, inSameDayAs: date)
            }.count
            return ActivityData(date: date, count: count)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Cards
                    overviewSection
                    
                    // Progress Ring
                    progressSection
                    
                    // Category Breakdown
                    categorySection
                    
                    // Activity Chart
                    activitySection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Total",
                    value: "\(totalBookmarks)",
                    icon: "bookmark.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Read",
                    value: "\(readBookmarks)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Unread",
                    value: "\(unreadBookmarks)",
                    icon: "circle.badge",
                    color: .orange
                )
                
                StatCard(
                    title: "Progress",
                    value: String(format: "%.0f%%", readPercentage),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            Text("Reading Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: readPercentage / 100)
                    .stroke(
                        LinearGradient(
                            colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth, value: readPercentage)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", readPercentage))
                        .font(.system(size: 40, weight: .bold))
                    Text("Complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(spacing: 16) {
            Text("Categories")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if categoryStats.isEmpty {
                Text("No categories yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 12) {
                    ForEach(categoryStats) { stat in
                        CategoryRow(stat: stat, total: totalBookmarks)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(spacing: 16) {
            Text("Last 7 Days Activity")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Chart(recentActivity) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .frame(height: 200)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    @Environment(ThemeManager.self) private var themeManager
    let stat: CategoryStat
    let total: Int
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(stat.count) / Double(total)
    }
    
    var body: some View {
        HStack {
            if let category = Category.allCases.first(where: { $0.rawValue.lowercased() == stat.name }) {
                Image(systemName: category.icon)
                    .foregroundStyle(category.color)
                Text(category.rawValue)
            } else {
                Text(stat.name.capitalized)
            }
            
            Spacer()
            
            Text("\(stat.count)")
                .font(.headline)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(width: 80, height: 8)
        }
    }
}

// MARK: - Models

struct CategoryStat: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct ActivityData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Bookmark.self, configurations: config)
    let themeManager = ThemeManager()
    
    // Add sample data
    for sample in Bookmark.samples {
        container.mainContext.insert(sample)
    }
    
    return StatisticsView()
        .modelContainer(container)
        .environment(themeManager)
}
