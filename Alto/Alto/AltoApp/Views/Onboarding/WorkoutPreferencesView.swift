import SwiftUI

struct WorkoutPreferencesView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeaderView(
                stepIndex: 4,
                totalSteps: viewModel.totalSteps,
                title: "Workout Preferences",
                subtitle: "Select workouts you enjoy. You can choose multiple options."
            )

            Text("Pick all that apply")
                .font(.headline)
                .foregroundStyle(AltoTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(WorkoutPreference.allCases) { workout in
                    let selected = viewModel.draft.preferredWorkouts.contains(workout)
                    Button {
                        if selected {
                            viewModel.draft.preferredWorkouts.remove(workout)
                        } else {
                            viewModel.draft.preferredWorkouts.insert(workout)
                        }
                    } label: {
                        HStack {
                            Text(workout.rawValue)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        }
                        .padding(12)
                        .foregroundStyle(selected ? AltoTheme.primary : AltoTheme.textPrimary)
                        .background(AltoTheme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selected ? AltoTheme.primary : AltoTheme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Selected: \(viewModel.draft.preferredWorkouts.map(\.rawValue).sorted().joined(separator: ", ").isEmpty ? "None yet" : viewModel.draft.preferredWorkouts.map(\.rawValue).sorted().joined(separator: ", "))")
                .font(.footnote)
                .foregroundStyle(AltoTheme.textSecondary)
                .altoCard()

            if viewModel.shouldShowCycleStep {
                Text("Next: menstrual cycle details")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
        }
    }
}
