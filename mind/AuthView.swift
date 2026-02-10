//
//  AuthView.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//

import SwiftUI

struct AuthView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    
    var body: some View {
        ZStack {
            // Background - themed
            LinearGradient(
                colors: themeManager.currentTheme.gradientColors.map { $0.opacity(3) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Logo and title
                    VStack(spacing: 16) {
                        Image("mindshelf_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Text("MindShelf")
                            .font(.largeTitle)
                            .bold()
                        
                        Text(localization.localizedString("auth.subtitle"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Language Switcher (Login screen)
                    HStack(spacing: 20) {
                        ForEach(LocalizationManager.AppLanguage.allCases) { language in
                            Button(action: {
                                withAnimation(.smooth) {
                                    localization.currentLanguage = language
                                }
                            }) {
                                Text("\(language.flag) \(language.rawValue)")
                                    .font(.caption)
                                    .fontWeight(localization.currentLanguage == language ? .bold : .regular)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        localization.currentLanguage == language ? .white.opacity(0.1) : .clear,
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(localization.currentLanguage == language ? .white.opacity(0.3) : .clear, lineWidth: 1)
                                    )
                            }
                            .foregroundStyle(localization.currentLanguage == language ? .primary : .secondary)
                        }
                    }
                    
                    // Secure notice
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                        Text(localization.localizedString("auth.secure"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        .ultraThinMaterial,
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    
                    // Form
                    VStack(spacing: 20) {
                        if isSignUp {
                            TextField(localization.localizedString("auth.name"), text: $name)
                                .textFieldStyle()
                                .textContentType(.name)
                        }
                        
                        TextField(localization.localizedString("auth.email"), text: $email)
                            .textFieldStyle()
                            .textContentType(.emailAddress)
                           .textInputAutocapitalization(.never)
                           .keyboardType(.emailAddress)
                           .autocorrectionDisabled(true)
                       
                       SecureField(localization.localizedString("auth.password"), text: $password)
                           .textFieldStyle()
                           .textContentType(isSignUp ? .newPassword : .password)
                       
                       if let error = authManager.error {
                           let lowerError = error.lowercased()
                           let localizedError = lowerError.contains("invalid login credentials") 
                               ? localization.localizedString("auth.error.invalid_credentials") 
                               : (lowerError.contains("network") ? localization.localizedString("auth.error.network") : error)
                           
                           Text(localizedError)
                               .font(.caption)
                               .foregroundStyle(.red)
                               .frame(maxWidth: .infinity, alignment: .leading)
                       }
                        
                        Button(action: authenticate) {
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? localization.localizedString("auth.signup") : localization.localizedString("auth.signin"))
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(theme: themeManager.currentTheme))
                        Button(action: { withAnimation { isSignUp.toggle() } }) {
                            Text(isSignUp ? localization.localizedString("auth.alreadyhave") : localization.localizedString("auth.donthave"))
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
        }
    }
    

    
    private func authenticate() {
        Task {
            if isSignUp {
                await authManager.signUp(email: email, name: name, password: password)
            } else {
                await authManager.signIn(email: email, password: password)
            }
        }
    }
}

// MARK: - Text Field Style

extension View {
    func textFieldStyle() -> some View {
        self
            .padding()
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
    }
}

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    let theme: AppTheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [theme.primaryColor, theme.secondaryColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: theme.primaryColor.opacity(0.3), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.smooth, value: configuration.isPressed)
    }
}

#Preview {
    AuthView()
        .environment(AuthManager())
        .environment(ThemeManager())
}
