import SwiftUI

struct RootView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel

    var body: some View {
        NavigationStack {
            if onboardingViewModel.isOnboardingComplete {
                DashboardView()
            } else {
                OnboardingContainerView()
            }
        }
    }
}
