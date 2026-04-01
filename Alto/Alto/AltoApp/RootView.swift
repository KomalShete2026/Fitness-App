import SwiftUI

struct RootView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @EnvironmentObject private var userStore: UserStore

    var body: some View {
        if onboardingViewModel.isOnboardingComplete || userStore.isOnboardingComplete {
            MainTabView()
        } else {
            NavigationStack {
                OnboardingContainerView()
            }
        }
    }
}
