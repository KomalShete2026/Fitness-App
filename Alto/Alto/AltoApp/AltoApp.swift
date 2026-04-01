import SwiftUI

@main
struct AltoApp: App {
    @StateObject private var onboardingViewModel = OnboardingViewModel(
        profileRepository: SupabaseProfileRepository()
    )
    @StateObject private var userStore = UserStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(onboardingViewModel)
                .environmentObject(userStore)
        }
    }
}
