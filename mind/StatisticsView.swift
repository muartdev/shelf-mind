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
    @Environment(LocalizationManager.self) private var localization
    @State private var showingPaywall = false
    @State private var activityDaysRange: Int = 7
    
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
        let now = Date()
        let days = (0..<activityDaysRange).map { calendar.date(byAdding: .day, value: -$0, to: now)! }
        
        return days.reversed().map { date in
            let startOfDate = calendar.startOfDay(for: date)
            let endOfDate = calendar.date(byAdding: .day, value: 1, to: startOfDate)!
            
            let count = bookmarks.filter { bookmark in
                bookmark.dateAdded >= startOfDate && bookmark.dateAdded < endOfDate
            }.count
            return ActivityData(date: startOfDate, count: count)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Stats
                    heroSection
                    
                    // Quick Overview
                    quickStatsSection
                    
                    // Activity Chart (Premium)
                    if !bookmarks.isEmpty {
                        if PaywallManager.shared.checkFeatureAccess(.advancedStatistics) {
                            activitySection
                        } else {
                            premiumLockedSection(
                                icon: "chart.bar.fill",
                                title: localization.localizedString("stats.activity")
                            )
                        }
                    }

                    // Category Breakdown (Premium)
                    if !categoryStats.isEmpty {
                        if PaywallManager.shared.checkFeatureAccess(.advancedStatistics) {
                            categorySection
                        } else {
                            premiumLockedSection(
                                icon: "folder.fill",
                                title: localization.localizedString("stats.categories")
                            )
                        }
                    }
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
            .navigationTitle(localization.localizedString("stats.title"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Premium Locked Section

    private func premiumLockedSection(icon: String, title: String) -> some View {
        Button(action: { showingPaywall = true }) {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                    Text(title)
                        .font(.headline)
                }
                Text(localization.localizedString("settings.upgrade"))
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .primary.opacity(0.06), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
    
    
    // MARK: - Hero Section (3 eşit kompakt kart)
    
    private var heroSection: some View {
        HStack(spacing: 10) {
            StatMiniCard(
                value: totalBookmarks,
                label: localization.localizedString("stats.total"),
                gradient: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor]
            )
            StatMiniCard(
                value: readBookmarks,
                label: localization.localizedString("stats.read"),
                icon: "checkmark.circle.fill",
                color: .green
            )
            StatMiniCard(
                value: unreadBookmarks,
                label: localization.localizedString("stats.toread"),
                icon: "circle.badge",
                color: .orange
            )
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                    Text(localization.localizedString("stats.progress"))
                        .font(.headline)
                }
                Spacer()
                Text(String(format: "%.0f%% \(localization.localizedString("stats.complete"))", readPercentage))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Modern progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                        )
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (readPercentage / 100))
                        .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.5), radius: 4, x: 0, y: 2)
                        .animation(.smooth(duration: 0.6), value: readPercentage)
                }
            }
            .frame(height: 16)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .primary.opacity(0.06), radius: 10, y: 5)
    }
    
    // MARK: - Overview Section (Removed)
    
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
    
    // MARK: - Progress Section (Removed)
    
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
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                    Text(localization.localizedString("stats.categories"))
                        .font(.headline)
                }
                Spacer()
                Text("\(categoryStats.count) \(localization.localizedString("stats.types"))")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(categoryStats.prefix(5)) { stat in
                    CategoryChip(stat: stat, total: totalBookmarks)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .primary.opacity(0.06), radius: 10, y: 5)
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                    Text(localization.localizedString("stats.activity"))
                        .font(.headline)
                }
                Spacer()
                Picker("", selection: $activityDaysRange) {
                    Text(localization.localizedString("stats.days.7")).tag(7)
                    Text(localization.localizedString("stats.days.14")).tag(14)
                    Text(localization.localizedString("stats.days.30")).tag(30)
                }
                .pickerStyle(.menu)
                .font(.caption)
            }
            
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
                .cornerRadius(8)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 160)
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .primary.opacity(0.06), radius: 10, y: 5)
    }
}


// MARK: - Stat Mini Card

struct StatMiniCard: View {
    @Environment(ThemeManager.self) private var themeManager
    let value: Int
    let label: String
    var icon: String? = nil
    var color: Color? = nil
    var gradient: [Color]? = nil
    
    var body: some View {
        VStack(spacing: 6) {
            if let icon, let color {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .foregroundStyle(valueForegroundStyle)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.15), lineWidth: 1))
        .shadow(color: .primary.opacity(0.08), radius: 8, y: 4)
    }
    
    private var valueForegroundStyle: AnyShapeStyle {
        if let gradient {
            AnyShapeStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        } else {
            AnyShapeStyle(color ?? themeManager.currentTheme.primaryColor)
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    @Environment(LocalizationManager.self) private var localization
    @Environment(ThemeManager.self) private var themeManager
    let stat: CategoryStat
    var total: Int = 1
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(stat.count) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let category = Category.fromStoredValue(stat.name) {
                    Circle()
                        .fill(category.color.gradient)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(stat.count) \(localization.localizedString("stats.bookmarks"))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.name.capitalized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(stat.count) \(localization.localizedString("stats.bookmarks"))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(stat.count)")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            // Yüzde bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            (Category.fromStoredValue(stat.name)?.color ?? themeManager.currentTheme.primaryColor)
                        )
                        .frame(width: max(4, geo.size.width * percentage))
                        .animation(.smooth(duration: 0.4), value: percentage)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.primary.opacity(0.06), lineWidth: 1))
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
            if let category = Category.fromStoredValue(stat.name) {
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
        .environment(LocalizationManager.shared)
}
