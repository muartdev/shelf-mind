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

    // MARK: - Computed Stats

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

    // MARK: - Insight Computed Properties

    /// Average bookmarks read per week (last 4 weeks)
    var readingPacePerWeek: Int {
        let calendar = Calendar.current
        guard let fourWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -4, to: Date()) else { return 0 }
        let recentlyRead = bookmarks.filter { $0.isRead && $0.dateAdded >= fourWeeksAgo }
        return max(1, recentlyRead.count / 4)
    }

    /// Most active weekday name (localized)
    var mostActiveDay: String {
        let calendar = Calendar.current
        let dayCounts = Dictionary(grouping: bookmarks, by: { calendar.component(.weekday, from: $0.dateAdded) })
            .mapValues { $0.count }
        guard let topDay = dayCounts.max(by: { $0.value < $1.value })?.key else { return "-" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.currentLanguage.code)
        return formatter.weekdaySymbols[topDay - 1]
    }

    /// Consecutive days with at least one read bookmark
    var currentStreak: Int {
        let calendar = Calendar.current
        let readDates = Set(
            bookmarks
                .filter { $0.isRead }
                .map { calendar.startOfDay(for: $0.dateAdded) }
        )
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        while readDates.contains(checkDate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
        }
        return streak
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if bookmarks.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: localization.localizedString("main.empty.default.title"),
                        message: localization.localizedString("main.empty.default.message")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            heroSection
                            insightsSection
                            progressRingSection

                            // Activity Chart (Premium)
                            if PaywallManager.shared.checkFeatureAccess(.advancedStatistics) {
                                activitySection
                            } else {
                                premiumLockedSection(
                                    icon: "chart.bar.fill",
                                    title: localization.localizedString("stats.activity")
                                )
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
                }
            }
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
            .shadow(color: .primary.opacity(0.1), radius: 15, x: 0, y: 8)
            .shadow(color: .primary.opacity(0.04), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        HStack(spacing: 10) {
            StatMiniCard(
                value: totalBookmarks,
                label: localization.localizedString("stats.total"),
                icon: "bookmark.fill",
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

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                Text(localization.localizedString("stats.insights"))
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                InsightItem(
                    icon: "speedometer",
                    label: localization.localizedString("stats.pace"),
                    value: "\(readingPacePerWeek)",
                    subtitle: localization.localizedString("stats.bookmarks.week"),
                    color: themeManager.currentTheme.primaryColor
                )

                InsightItem(
                    icon: "calendar",
                    label: localization.localizedString("stats.most.active"),
                    value: mostActiveDay,
                    color: themeManager.currentTheme.secondaryColor
                )

                InsightItem(
                    icon: "flame.fill",
                    label: localization.localizedString("stats.streak"),
                    value: currentStreak > 0
                        ? String(format: localization.localizedString("stats.streak.days"), currentStreak)
                        : localization.localizedString("stats.no.streak"),
                    color: .orange
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.15), lineWidth: 1))
        .shadow(color: .primary.opacity(0.1), radius: 15, x: 0, y: 8)
        .shadow(color: .primary.opacity(0.04), radius: 5, x: 0, y: 2)
    }

    // MARK: - Progress Ring Section

    private var progressRingSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                Text(localization.localizedString("stats.progress"))
                    .font(.headline)
                Spacer()
            }

            ZStack {
                // Background track
                Circle()
                    .stroke(.quaternary, lineWidth: 16)
                    .frame(width: 160, height: 160)

                // Gradient fill
                Circle()
                    .trim(from: 0, to: readPercentage / 100)
                    .stroke(
                        LinearGradient(
                            colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth(duration: 0.8), value: readPercentage)
                    .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 6, x: 0, y: 3)

                // Center text
                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", readPercentage))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text(localization.localizedString("stats.complete"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)

            // Legend
            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(themeManager.currentTheme.primaryColor)
                        .frame(width: 8, height: 8)
                    Text("\(readBookmarks) \(localization.localizedString("stats.read"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(.quaternary)
                        .frame(width: 8, height: 8)
                    Text("\(unreadBookmarks) \(localization.localizedString("stats.toread"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.15), lineWidth: 1))
        .shadow(color: .primary.opacity(0.1), radius: 15, x: 0, y: 8)
        .shadow(color: .primary.opacity(0.04), radius: 5, x: 0, y: 2)
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.15), lineWidth: 1))
        .shadow(color: .primary.opacity(0.1), radius: 15, x: 0, y: 8)
        .shadow(color: .primary.opacity(0.04), radius: 5, x: 0, y: 2)
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
                    y: .value("Count", item.count),
                    width: activityDaysRange <= 7 ? .fixed(20) : (activityDaysRange <= 14 ? .fixed(12) : .fixed(6))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: activityDaysRange <= 7 ? 1 : (activityDaysRange <= 14 ? 2 : 5))) { _ in
                    AxisValueLabel(format: activityDaysRange <= 7
                        ? .dateTime.weekday(.narrow)
                        : .dateTime.day(.twoDigits).month(.abbreviated))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 180)
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.15), lineWidth: 1))
        .shadow(color: .primary.opacity(0.1), radius: 15, x: 0, y: 8)
        .shadow(color: .primary.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}


// MARK: - Stat Mini Card

struct StatMiniCard: View {
    @Environment(ThemeManager.self) private var themeManager
    let value: Int
    let label: String
    var icon: String = "bookmark.fill"
    var color: Color? = nil
    var gradient: [Color]? = nil

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accentStyle)

            Text("\(value)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .foregroundStyle(accentStyle)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.15), lineWidth: 1))
        .shadow(color: .primary.opacity(0.1), radius: 15, x: 0, y: 8)
        .shadow(color: .primary.opacity(0.04), radius: 5, x: 0, y: 2)
    }

    private var accentStyle: AnyShapeStyle {
        if let gradient {
            AnyShapeStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        } else {
            AnyShapeStyle(color ?? themeManager.currentTheme.primaryColor)
        }
    }
}

// MARK: - Insight Item

struct InsightItem: View {
    let icon: String
    let label: String
    let value: String
    var subtitle: String = ""
    var color: Color = .blue

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
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

            // Percentage bar
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.primary.opacity(0.15), lineWidth: 1))
        .shadow(color: .primary.opacity(0.08), radius: 10, x: 0, y: 5)
        .shadow(color: .primary.opacity(0.03), radius: 3, x: 0, y: 1)
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
