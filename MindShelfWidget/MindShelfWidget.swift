//
//  MindShelfWidget.swift
//  MindShelfWidget
//
//  Widget showing unread count and recent bookmarks.
//

import WidgetKit
import SwiftUI

private let appGroupID = "group.com.muartdev.mind"

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), unreadCount: 3, totalCount: 12, recentTitles: ["Article 1", "Article 2", "Article 3"])
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = makeEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry() -> WidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        let unread = defaults?.integer(forKey: "widget_unread_count") ?? 0
        let total = defaults?.integer(forKey: "widget_total_count") ?? 0
        let recent = defaults?.stringArray(forKey: "widget_recent_titles") ?? []
        return WidgetEntry(date: Date(), unreadCount: unread, totalCount: total, recentTitles: recent)
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let unreadCount: Int
    let totalCount: Int
    let recentTitles: [String]
}

struct MindShelfWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        Link(destination: URL(string: "mind://bookmarks")!) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Image(systemName: "bookmark.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                    Spacer()
                    if entry.unreadCount > 0 {
                        Text("\(entry.unreadCount)")
                            .font(.callout.bold().monospacedDigit())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.red))
                            .fixedSize()
                    }
                }
                Spacer()
                Text("Mind Shelf")
                    .font(.footnote.bold())
                    .foregroundStyle(.primary)
                HStack(spacing: 4) {
                    Text("\(entry.unreadCount) unread")
                        .foregroundStyle(.red)
                    Text("·")
                    Text("\(entry.totalCount) total")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .padding()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        Link(destination: URL(string: "mind://bookmarks")!) {
            HStack(spacing: 16) {
                // Left side - stats
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark.fill")
                            .font(.title3)
                            .foregroundStyle(.tint)
                        Text("Mind Shelf")
                            .font(.headline)
                    }

                    if entry.unreadCount > 0 {
                        Text("\(entry.unreadCount) unread")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(.red))
                            .fixedSize()
                    }

                    Spacer()

                    Text("\(entry.totalCount) bookmarks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !entry.recentTitles.isEmpty {
                    Divider()

                    // Right side - recent bookmarks
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Recent")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        ForEach(entry.recentTitles.prefix(3), id: \.self) { title in
                            Text(title)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MindShelfWidget: Widget {
    let kind: String = "MindShelfWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MindShelfWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Mind Shelf")
        .description("See your unread count and recent bookmarks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    MindShelfWidget()
} timeline: {
    WidgetEntry(date: Date(), unreadCount: 5, totalCount: 24, recentTitles: ["SwiftUI Tips", "WWDC Notes", "Design System"])
}
