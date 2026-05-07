/// Pure launch and subscription-management decisions that keep the iOS app aligned
/// with App Store review requirements.
enum AppStoreReviewPolicy {
    static let subscriptionManagementPresentation: SubscriptionManagementPresentation = .nativeAppStoreSheet

    static func launchDestination(
        hasCompletedOnboarding: Bool,
        isAuthenticated: Bool,
        isGuestMode: Bool,
        isRequestingAccountSignIn: Bool = false
    ) -> AppLaunchDestination {
        guard hasCompletedOnboarding else {
            return .onboarding
        }

        if isAuthenticated || isGuestMode {
            return .mainApp
        }

        if isRequestingAccountSignIn {
            return .authentication
        }

        return .mainApp
    }

    static func shouldEnterGuestModeAfterLaunch(
        hasCompletedOnboarding: Bool,
        isAuthenticated: Bool,
        isGuestMode: Bool,
        isRequestingAccountSignIn: Bool = false
    ) -> Bool {
        hasCompletedOnboarding &&
            !isAuthenticated &&
            !isGuestMode &&
            !isRequestingAccountSignIn
    }
}

enum AppLaunchDestination {
    case onboarding
    case mainApp
    case authentication
}

enum SubscriptionManagementPresentation {
    case nativeAppStoreSheet
}
