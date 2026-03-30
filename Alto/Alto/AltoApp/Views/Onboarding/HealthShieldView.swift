import SwiftUI

struct HealthShieldView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeaderView(
                stepIndex: 2,
                totalSteps: viewModel.totalSteps,
                title: "Health Conditions",
                subtitle: "Tell Alto about health conditions so your plan stays safe."
            )

            ForEach(HealthCondition.allCases) { condition in
                let isSelected = viewModel.draft.selectedConditions.contains(condition)

                Button {
                    viewModel.toggleCondition(condition)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .foregroundStyle(isSelected ? AltoTheme.primary : AltoTheme.border)
                        Text(condition.rawValue)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AltoTheme.textPrimary)
                        Spacer()
                    }
                    .padding(14)
                    .background(AltoTheme.card)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AltoTheme.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            if viewModel.draft.selectedConditions.contains(.other) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe your health condition")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AltoTheme.primary)
                    TextEditor(text: $viewModel.draft.otherConditionText)
                        .frame(minHeight: 96)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(AltoTheme.card)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AltoTheme.border, lineWidth: 1))
                        .foregroundStyle(AltoTheme.textPrimary)
                }
            }

            if viewModel.draft.selectedConditions.contains(.heartCondition) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medical Disclaimer")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.red)
                    Text("Please consult a physician before high-intensity activity.")
                        .foregroundStyle(AltoTheme.textSecondary)
                }
                .padding()
                .background(Color.red.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.4), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                Text("This data stays on-device for AI tuning only.")
            }
            .font(.footnote)
            .foregroundStyle(AltoTheme.textSecondary)
        }
    }
}
