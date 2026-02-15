//
//  ThemeManager.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI

@Observable
@MainActor
final class ThemeManager {
    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.bluePurpleLight.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .bluePurpleLight
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case bluePurpleLight = "Blue Purple Light"
    case orangePinkLight = "Orange Pink Light"
    case bluePurpleDark = "Blue Purple Dark"
    case orangePinkDark = "Orange Pink Dark"
    
    var id: String { rawValue }
    
    var isDark: Bool {
        switch self {
        case .bluePurpleDark, .orangePinkDark:
            return true
        case .bluePurpleLight, .orangePinkLight:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .bluePurpleLight, .bluePurpleDark:
            return LocalizationManager.shared.localizedString("theme.blue.purple")
        case .orangePinkLight, .orangePinkDark:
            return LocalizationManager.shared.localizedString("theme.orange.pink")
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .bluePurpleLight, .bluePurpleDark:
            return .blue
        case .orangePinkLight, .orangePinkDark:
            return .orange
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .bluePurpleLight, .bluePurpleDark:
            return .purple
        case .orangePinkLight, .orangePinkDark:
            return .pink
        }
    }
    
    var gradientColors: [Color] {
        [primaryColor.opacity(isDark ? 0.35 : 0.2),
         secondaryColor.opacity(isDark ? 0.35 : 0.2)]
    }
    
    var accentColor: Color {
        switch self {
        case .bluePurpleLight, .bluePurpleDark:
            return .blue
        case .orangePinkLight, .orangePinkDark:
            return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .bluePurpleLight:
            return "sun.max.fill"
        case .orangePinkLight:
            return "sun.max.fill"
        case .bluePurpleDark:
            return "moon.fill"
        case .orangePinkDark:
            return "moon.fill"
        }
    }
    
    var previewGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Adaptive Colors

extension AppTheme {
    /// Adaptive border color: visible on both light and dark backgrounds
    var borderColor: Color {
        isDark ? .white.opacity(0.2) : .black.opacity(0.1)
    }

    /// Adaptive shadow color
    var shadowColor: Color {
        isDark ? .black.opacity(0.3) : .black.opacity(0.12)
    }

    /// Lighter shadow for subtle depth
    var shadowColorLight: Color {
        isDark ? .black.opacity(0.15) : .black.opacity(0.06)
    }
}

// View extension for themed backgrounds
extension View {
    func themedBackground(_ theme: AppTheme) -> some View {
        self.background(
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}
