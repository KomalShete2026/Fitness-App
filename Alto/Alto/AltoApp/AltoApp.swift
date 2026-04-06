import SwiftUI

@main
struct AltoApp: App {
    @StateObject private var onboardingViewModel = OnboardingViewModel(
        profileRepository: SupabaseProfileRepository()
    )
    @StateObject private var userStore = UserStore()
    @StateObject private var userSettings = UserSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(onboardingViewModel)
                .environmentObject(userStore)
                .environmentObject(userSettings)
        }
    }
}
