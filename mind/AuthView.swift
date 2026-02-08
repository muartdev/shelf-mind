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
                        Image(systemName: "book.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(themeManager.currentTheme.primaryColor)
                        
                        Text("MindShelf")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Save and organize your favorite content")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Demo account notice
                    VStack(spacing: 8) {
                        Text("Demo Mode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Any email + 6+ char password works")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("(Supabase integration coming soon)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    .padding(.horizontal)
                    
                    // Form
                    VStack(spacing: 20) {
                        if isSignUp {
                            TextField("Name", text: $name)
                                .textFieldStyle()
                                .textContentType(.name)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle()
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle()
                            .textContentType(isSignUp ? .newPassword : .password)
                        
                        if let error = authManager.error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Button(action: authenticate) {
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? "Sign Up" : "Sign In")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(theme: themeManager.currentTheme))
                        .disabled(authManager.isLoading)
                        
                        // Quick demo button
                        Button(action: quickDemo) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Quick Demo")
                            }
                            .font(.subheadline)
                        }
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                        
                        Button(action: { withAnimation { isSignUp.toggle() } }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
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
    
    private func quickDemo() {
        email = "demo@mindshelf.app"
        password = "demo123"
        Task {
            await authManager.signIn(email: email, password: password)
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
