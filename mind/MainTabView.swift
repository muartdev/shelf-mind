//
//  MainTabView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI

struct MainTabView: View {
    @Environment(LocalizationManager.self) private var localization
    
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
}
