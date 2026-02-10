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
    @State private var verificationCode = ""
    
    var body: some View {
        ZStack {
            // Background - themed
            LinearGradient(
                colors: themeManager.currentTheme.gradientColors.map { $0.opacity(0.3) },
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
                            .frame(width: 96, height: 96)
                            .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.2), radius: 12, x: 0, y: 6)
                        
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

                       if authManager.needsEmailConfirmation {
                           VStack(alignment: .leading, spacing: 8) {
                               Text(localization.localizedString("auth.verify.title"))
                                   .font(.caption)
                                   .foregroundStyle(.secondary)
                               Text(localization.localizedString("auth.verify.message"))
                                   .font(.caption)
                                   .foregroundStyle(.secondary)
                               if let pendingEmail = authManager.pendingEmail {
                                   Text(pendingEmail)
                                       .font(.caption2)
                                       .foregroundStyle(.secondary)
                               }
                               TextField(localization.localizedString("auth.verify.code.placeholder"), text: $verificationCode)
                                   .textFieldStyle()
                                   .keyboardType(.numberPad)
                                   .textInputAutocapitalization(.never)
                               Button(localization.localizedString("auth.verify.button")) {
                                   Task { await authManager.verifyEmailOTP(code: verificationCode) }
                               }
                               .font(.caption)
                               Button(localization.localizedString("auth.verify.resend")) {
                                   Task { await authManager.resendConfirmation() }
                               }
                               .font(.caption)
                           }
                           .frame(maxWidth: .infinity, alignment: .leading)
                       }

                       if let infoKey = authManager.infoKey {
                           Text(localization.localizedString(infoKey))
                               .font(.caption)
                               .foregroundStyle(.green)
                               .frame(maxWidth: .infinity, alignment: .leading)
                       }
                       
                       if let error = authManager.error {
                           Text(getLocalizedError(error))
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
    
    private func getLocalizedError(_ error: String) -> String {
        let lowerError = error.lowercased()
        
        if error == "auth.error.profile_missing" {
            return localization.localizedString("auth.error.profile_missing")
        }
        if lowerError.contains("invalid login credentials") {
            return localization.localizedString("auth.error.invalid_credentials")
        } else if lowerError.contains("missing email or phone") {
            return localization.localizedString("auth.error.missing_email")
        } else if lowerError.contains("at least 6 characters") {
            return localization.localizedString("auth.error.password_too_short")
        } else if lowerError.contains("already registered") {
            return localization.localizedString("auth.error.already_registered")
        } else if lowerError.contains("email not confirmed") || lowerError.contains("confirm your email") {
            return localization.localizedString("auth.error.email_not_confirmed")
        } else if lowerError.contains("invalid") && lowerError.contains("otp") {
            return localization.localizedString("auth.error.invalid_code")
        } else if lowerError.contains("network") {
            return localization.localizedString("auth.error.network")
        } else {
            return error
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
