import SwiftUI

struct GoalTimelineView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeaderView(
                stepIndex: 5,
                totalSteps: viewModel.totalSteps,
                title: "Goal & Timeline",
                subtitle: "Set your north-star goal and target timeframe."
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("GOAL")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AltoTheme.primary)
                TextField("Example: Hyrox", text: $viewModel.draft.goalName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding()
                    .background(AltoTheme.card)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AltoTheme.border, lineWidth: 1))
                    .foregroundStyle(AltoTheme.textPrimary)
            }
            .altoCard()

            VStack(alignment: .leading, spacing: 10) {
                Text("TIMELINE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AltoTheme.primary)

                HStack(spacing: 10) {
                    Picker("Value", selection: $viewModel.draft.goalTimelineValue) {
                        ForEach(1...24, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AltoTheme.primary)

                    Picker("Unit", selection: $viewModel.draft.goalTimelineUnit) {
                        ForEach(GoalTimelineUnit.allCases) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(AltoTheme.primary)
                }

                Text("Example: \(viewModel.draft.goalName.isEmpty ? "Hyrox" : viewModel.draft.goalName) in \(viewModel.draft.goalTimelineValue) \(viewModel.draft.goalTimelineUnit.rawValue)")
                    .font(.footnote)
                    .foregroundStyle(AltoTheme.textSecondary)
            }
            .altoCard()

            if viewModel.shouldShowCycleStep {
                Text("Next: menstrual cycle details")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
        }
    }
}
