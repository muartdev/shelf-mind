import Testing
@testable import MindShelfCore

@Suite("App Store review access policy")
struct AppStoreReviewPolicyTests {

    @Test("finished onboarding without account opens the main app")
    func finishedOnboardingWithoutAccountOpensMainApp() {
        let destination = AppStoreReviewPolicy.launchDestination(
            hasCompletedOnboarding: true,
            isAuthenticated: false,
            isGuestMode: false
        )

        #expect(destination == .mainApp)
    }

    @Test("finished onboarding without account starts local guest mode")
    func finishedOnboardingWithoutAccountStartsGuestMode() {
        #expect(
            AppStoreReviewPolicy.shouldEnterGuestModeAfterLaunch(
                hasCompletedOnboarding: true,
                isAuthenticated: false,
                isGuestMode: false
            )
        )
    }

    @Test("subscription management uses native App Store UI")
    func subscriptionManagementUsesNativeAppStoreUI() {
        #expect(AppStoreReviewPolicy.subscriptionManagementPresentation == .nativeAppStoreSheet)
    }

    @Test("explicit sign-in request opens authentication")
    func explicitSignInRequestOpensAuthentication() {
        let destination = AppStoreReviewPolicy.launchDestination(
            hasCompletedOnboarding: true,
            isAuthenticated: false,
            isGuestMode: false,
            isRequestingAccountSignIn: true
        )

        #expect(destination == .authentication)
    }
}
