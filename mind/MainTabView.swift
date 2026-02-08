//
//  MainTabView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark.fill")
                }
            
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthManager())
        .environment(ThemeManager())
}
