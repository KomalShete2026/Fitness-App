import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 14) {
            ScrollView {
                Group {
                    switch viewModel.currentStep {
                    case .personal:
                        PersonalProfileView()
                    case .healthShield:
                        HealthShieldView()
                    case .activityLevel:
                        ActivityLevelView()
                    case .workoutPreferences:
                        WorkoutPreferencesView()
                    case .goalTimeline:
                        GoalTimelineView()
                    case .cycleDetails:
                        CycleDetailsView()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let error = viewModel.saveError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                if viewModel.currentStep != .personal {
                    Button("Back") {
                        viewModel.moveBack()
                    }
                    .buttonStyle(.bordered)
                    .tint(AltoTheme.textSecondary)
                }

                Button(viewModel.isLastStep ? "Finish → Home" : "Continue →") {
                    if viewModel.isLastStep {
                        Task { await viewModel.submitOnboarding() }
                    } else {
                        viewModel.moveForward()
                    }
                }
                .buttonStyle(AltoPrimaryButtonStyle())
                .disabled(!viewModel.canContinue || viewModel.isSaving)
            }
        }
        .padding(20)
        .background(AltoTheme.background.ignoresSafeArea())
        .alert("Medical Disclaimer", isPresented: $viewModel.showHeartDisclaimer) {
            Button("I Understand", role: .cancel) { }
        } message: {
            Text("Please consult a physician before high-intensity activity.")
        }
    }
}
