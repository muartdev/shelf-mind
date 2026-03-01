//
//  MainTabView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI
import SwiftData
import UIKit

struct MainTabView: View {
    @Environment(LocalizationManager.self) private var localization
    @Environment(ThemeManager.self) private var themeManager

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)

        // Unselected items: muted gray
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs

        // Selected items: handled by .tint() from mindApp

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label(localization.localizedString("tab.bookmarks"), systemImage: "bookmark.fill")
                }

            StatisticsView()
                .tabItem {
                    Label(localization.localizedString("tab.statistics"), systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label(localization.localizedString("tab.settings"), systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthManager())
        .environment(ThemeManager())
        .environment(LocalizationManager.shared)
        .modelContainer(for: [Bookmark.self, User.self], inMemory: true)
}
