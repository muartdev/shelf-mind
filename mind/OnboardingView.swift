//
//  OnboardingView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                icon: "bookmark.fill",
                title: localization.localizedString("onboarding.page1.title"),
                description: localization.localizedString("onboarding.page1.desc"),
                color: .blue
            ),
            OnboardingPage(
                icon: "folder.fill",
                title: localization.localizedString("onboarding.page2.title"),
                description: localization.localizedString("onboarding.page2.desc"),
                color: .purple
            ),
            OnboardingPage(
                icon: "sparkles",
                title: localization.localizedString("onboarding.page3.title"),
                description: localization.localizedString("onboarding.page3.desc"),
                color: .green
            )
        ]
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [pages[currentPage].color.opacity(0.3), pages[currentPage].color.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.smooth, value: currentPage)
            
            VStack(spacing: 40) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(localization.localizedString("onboarding.skip")) {
                            completeOnboarding()
                        }
                        .foregroundStyle(.secondary)
                        .padding()
                    }
                }
                
                Spacer()
                
                // Page content
                VStack(spacing: 30) {
                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 80))
                        .foregroundStyle(pages[currentPage].color)
                        .shadow(color: pages[currentPage].color.opacity(0.3), radius: 20, x: 0, y: 10)
                        .transition(.scale.combined(with: .opacity))
                        .id("icon-\(currentPage)")
                    
                    VStack(spacing: 16) {
                        Text(pages[currentPage].title)
                            .font(.largeTitle)
                            .bold()
                            .transition(.opacity)
                            .id("title-\(currentPage)")
                        
                        Text(pages[currentPage].description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .transition(.opacity)
                            .id("description-\(currentPage)")
                    }
                    .padding(32)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 24)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .primary.opacity(0.08), radius: 20, x: 0, y: 10)
                    .shadow(color: .primary.opacity(0.04), radius: 5, x: 0, y: 2)
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.smooth, value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Next/Get Started button
                Button(action: nextPage) {
                    Text(currentPage == pages.count - 1 ? localization.localizedString("onboarding.start") : localization.localizedString("onboarding.next"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: pages[currentPage].color.opacity(0.4), radius: 15, x: 0, y: 8)
                        .shadow(color: .primary.opacity(0.08), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation(.smooth) {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    OnboardingView()
        .environment(ThemeManager())
}
