import SwiftUI

@main
struct AltoApp: App {
    @StateObject private var onboardingViewModel = OnboardingViewModel(
        profileRepository: SupabaseProfileRepository()
    )

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(onboardingViewModel)
        }
    }
}
