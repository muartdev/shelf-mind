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
    @FocusState private var focusedField: Field?
    private let otpLength = 6
    @State private var resendCooldown = 0
    @State private var resendTask: Task<Void, Never>?
    @State private var showingResetSheet = false
    @State private var resetEmail = ""
    @State private var resetError: String?
    @State private var resetSent = false
    @State private var isResetLoading = false

    private enum Field {
        case name
        case email
        case password
        case otp
    }
    
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
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 16, x: 0, y: 8)
                        
                        Text("MindShelf")
                            .font(.largeTitle)
                            .bold()
                        
                        Text(localization.localizedString("auth.subtitle"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Language Switcher
                    Menu {
                        ForEach(LocalizationManager.AppLanguage.allCases) { language in
                            Button(action: {
                                withAnimation(.smooth) {
                                    localization.currentLanguage = language
                                }
                            }) {
                                HStack {
                                    Text("\(language.flag) \(language.rawValue)")
                                    if localization.currentLanguage == language {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.subheadline)
                            Text("\(localization.currentLanguage.flag) \(localization.currentLanguage.rawValue)")
                                .font(.subheadline)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
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
                            .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .primary.opacity(0.08), radius: 8, y: 4)
                    
                    // Form
                    VStack(spacing: 20) {
                        if authManager.needsEmailConfirmation {
                            verificationSection
                        } else {
                            if isSignUp {
                                TextField(localization.localizedString("auth.name"), text: $name)
                                    .textFieldStyle()
                                    .textContentType(.name)
                                    .focused($focusedField, equals: .name)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .email }
                            }
                            
                            TextField(localization.localizedString("auth.email"), text: $email)
                                .textFieldStyle()
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled(true)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                            
                            SecureField(localization.localizedString("auth.password"), text: $password)
                                .textFieldStyle()
                                .textContentType(isSignUp ? .newPassword : .password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.done)
                                .onSubmit { focusedField = nil }
                        }

                       if let infoKey = authManager.infoKey {
                           Text(localization.localizedString(infoKey))
                               .font(.caption)
                               .foregroundStyle(.green)
                               .frame(maxWidth: .infinity, alignment: .leading)
                       }
                       
                       if isSignUp && !password.isEmpty && password.count < 6 {
                           Label(localization.localizedString("auth.error.password_too_short"), systemImage: "exclamationmark.circle.fill")
                               .font(.caption2)
                               .foregroundStyle(.orange)
                               .padding(.horizontal, 8)
                               .padding(.vertical, 4)
                               .background(.orange.opacity(0.1), in: Capsule())
                               .frame(maxWidth: .infinity, alignment: .leading)
                               .transition(.move(edge: .top).combined(with: .opacity))
                       }
                       
                       if let error = authManager.error {
                           HStack(alignment: .top, spacing: 12) {
                               Image(systemName: "exclamationmark.circle.fill")
                                   .font(.title3)
                                   .foregroundStyle(.red)
                               Text(getLocalizedError(error))
                                   .font(.subheadline)
                                   .foregroundStyle(.primary)
                                   .multilineTextAlignment(.leading)
                           }
                           .frame(maxWidth: .infinity, alignment: .leading)
                           .padding(16)
                           .background(
                               RoundedRectangle(cornerRadius: 12)
                                   .fill(.red.opacity(0.12))
                           )
                           .overlay(
                               RoundedRectangle(cornerRadius: 12)
                                   .strokeBorder(.red.opacity(0.4), lineWidth: 1)
                           )
                       }
                        
                        if !authManager.needsEmailConfirmation {
                            Button(action: authenticate) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? localization.localizedString("auth.signup") : localization.localizedString("auth.signin"))
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle(theme: themeManager.currentTheme))
                            .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || 
                                     (isSignUp && (name.isEmpty || password.count < 6)))
                            
                            if !isSignUp {
                                Button(localization.localizedString("auth.forgot")) {
                                    resetEmail = email
                                    resetError = nil
                                    resetSent = false
                                    showingResetSheet = true
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
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
                            .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .primary.opacity(0.1), radius: 20, x: 0, y: 10)
                    .shadow(color: .primary.opacity(0.04), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .contentShape(Rectangle())
        .onTapGesture { focusedField = nil }
        .sheet(isPresented: $showingResetSheet) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text(localization.localizedString("auth.reset.title"))
                        .font(.headline)
                    Text(localization.localizedString("auth.reset.subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    TextField(localization.localizedString("auth.email"), text: $resetEmail)
                        .textFieldStyle()
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled(true)
                    
                    if let resetError {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.red)
                            Text(getLocalizedError(resetError))
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.red.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.red.opacity(0.4), lineWidth: 1)
                        )
                    }
                    
                    if resetSent {
                        Text(localization.localizedString("auth.reset.sent"))
                            .font(.caption)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button {
                        Task {
                            resetError = nil
                            resetSent = false
                            guard !resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                resetError = localization.localizedString("auth.error.missing_email")
                                return
                            }
                            isResetLoading = true
                            defer { isResetLoading = false }
                            do {
                                try await authManager.sendPasswordReset(email: resetEmail)
                                resetSent = true
                            } catch {
                                resetError = error.localizedDescription
                            }
                        }
                    } label: {
                        if isResetLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(localization.localizedString("auth.reset.send"))
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(theme: themeManager.currentTheme))
                    .disabled(isResetLoading)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle(localization.localizedString("auth.reset.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(localization.localizedString("common.cancel")) {
                            showingResetSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onChange(of: authManager.infoKey) { _, newValue in
            if newValue == "auth.verify.sent" {
                verificationCode = ""
                startResendCooldown(seconds: 60)
            }
        }
    }

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localizedString("auth.verify.title"))
                .font(.headline)
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
                .textContentType(.oneTimeCode)
                .focused($focusedField, equals: .otp)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
                .onChange(of: verificationCode) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        verificationCode = filtered
                    }
                    if verificationCode.count > otpLength {
                        verificationCode = String(verificationCode.prefix(otpLength))
                    }
                }

            Button(localization.localizedString("auth.verify.button")) {
                Task { await authManager.verifyEmailOTP(code: verificationCode) }
            }
            .buttonStyle(PrimaryButtonStyle(theme: themeManager.currentTheme))
            .disabled(authManager.isLoading || verificationCode.count < otpLength)

            Button(resendButtonTitle) {
                Task { await authManager.resendConfirmation() }
            }
            .font(.caption)
            .disabled(authManager.isLoading || resendCooldown > 0)

            Button(localization.localizedString("auth.verify.change_email")) {
                authManager.cancelEmailVerification()
                verificationCode = ""
                resendCooldown = 0
                resendTask?.cancel()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var resendButtonTitle: String {
        if resendCooldown > 0 {
            return String(format: localization.localizedString("auth.verify.resend_in"), resendCooldown)
        }
        return localization.localizedString("auth.verify.resend")
    }

    private func startResendCooldown(seconds: Int) {
        resendTask?.cancel()
        resendCooldown = seconds
        resendTask = Task { @MainActor in
            while resendCooldown > 0 {
                try? await Task.sleep(for: .seconds(1))
                resendCooldown -= 1
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
        } else if lowerError.contains("already exists") || lowerError.contains("email") && lowerError.contains("exists") {
            return localization.localizedString("auth.error.already_registered")
        } else if lowerError.contains("email not confirmed") || lowerError.contains("confirm your email") {
            return localization.localizedString("auth.error.email_not_confirmed")
        } else if lowerError.contains("token has expired")
                    || (lowerError.contains("token") && lowerError.contains("invalid"))
                    || (lowerError.contains("invalid") && lowerError.contains("otp")) {
            return localization.localizedString("auth.error.invalid_code")
        } else if lowerError.contains("rate limit") || lowerError.contains("too many requests") {
            return localization.localizedString("auth.error.rate_limit")
        } else if lowerError.contains("security purposes") && lowerError.contains("seconds") {
            return localization.localizedString("auth.error.resend_wait")
        } else if lowerError.contains("network") {
            return localization.localizedString("auth.error.network")
        } else {
            return error
        }
    }


    
    private func authenticate() {
        focusedField = nil
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
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
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
            .shadow(color: .primary.opacity(0.08), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.smooth, value: configuration.isPressed)
    }
}

#Preview {
    AuthView()
        .environment(AuthManager())
        .environment(ThemeManager())
}
