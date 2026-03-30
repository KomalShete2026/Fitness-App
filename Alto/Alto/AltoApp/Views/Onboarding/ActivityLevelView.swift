import SwiftUI

struct ActivityLevelView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeaderView(
                stepIndex: 3,
                totalSteps: viewModel.totalSteps,
                title: "Current Activity Rhythm",
                subtitle: "Tell Alto how active you are right now."
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("ACTIVITY PROFILE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AltoTheme.primary)

                Picker("Activity profile", selection: $viewModel.draft.activityPreset) {
                    ForEach(ActivityPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .tint(AltoTheme.primary)
            }
            .altoCard()

            if viewModel.draft.activityPreset == .custom {
                VStack(alignment: .leading, spacing: 10) {
                    Text("FREQUENCY")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AltoTheme.primary)

                    HStack {
                        Text("\(viewModel.draft.activityFrequencyValue)")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AltoTheme.textPrimary)
                        Text("times")
                            .foregroundStyle(AltoTheme.textSecondary)
                        Spacer()
                    }

                    Stepper("Times", value: $viewModel.draft.activityFrequencyValue, in: 0...60)
                        .labelsHidden()
                        .tint(AltoTheme.primary)

                    Picker("Frequency unit", selection: $viewModel.draft.activityFrequencyUnit) {
                        Text("Weekly").tag(ActivityFrequencyUnit.weekly)
                        Text("Monthly").tag(ActivityFrequencyUnit.monthly)
                    }
                    .pickerStyle(.segmented)
                    .tint(AltoTheme.primary)

                    Text("Summary: \(viewModel.draft.activitySummary)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AltoTheme.textSecondary)
                }
                .altoCard()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected: \(viewModel.draft.activitySummary)")
                        .font(.headline)
                        .foregroundStyle(AltoTheme.textPrimary)
                    Text("You can adjust this later in settings.")
                        .font(.footnote)
                        .foregroundStyle(AltoTheme.textSecondary)
                }
                .altoCard()
            }

            if viewModel.shouldShowCycleStep {
                Text("Next: menstrual cycle details")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
        }
    }
}
