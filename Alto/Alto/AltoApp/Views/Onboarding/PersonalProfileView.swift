import SwiftUI

struct PersonalProfileView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 16) {
            StepHeaderView(
                stepIndex: 1,
                totalSteps: viewModel.totalSteps,
                title: "Your Identity",
                subtitle: "Let's build your metabolic baseline to personalize your journey."
            )

            HStack(spacing: 14) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AltoTheme.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Train smart. Feel unstoppable.")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AltoTheme.textPrimary)
                    Text("Set your identity once, Alto adapts every workout after.")
                        .font(.footnote)
                        .foregroundStyle(AltoTheme.textSecondary)
                }
                Spacer()
            }
            .altoCard()

            VStack(alignment: .leading, spacing: 8) {
                Text("FULL NAME *")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AltoTheme.primary)
                TextField("Enter your name", text: $viewModel.draft.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding()
                    .background(AltoTheme.card)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AltoTheme.border, lineWidth: 1))
                    .foregroundStyle(AltoTheme.textPrimary)
            }
            .altoCard()

            VStack(alignment: .leading, spacing: 10) {
                Text("GENDER")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AltoTheme.primary)
                Picker("Gender", selection: Binding(
                    get: { viewModel.draft.gender },
                    set: { viewModel.updateGender($0) }
                )) {
                    ForEach(Gender.allCases) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .pickerStyle(.segmented)
                .tint(AltoTheme.primary)
            }
            .altoCard()

            VStack(alignment: .leading, spacing: 14) {
                Text("PHYSICAL STATS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AltoTheme.primary)

                statRow(
                    title: "Age",
                    valueText: "\(viewModel.draft.age)",
                    unitText: "years"
                ) {
                    Picker("Age", selection: $viewModel.draft.age) {
                        ForEach(10...90, id: \.self) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AltoTheme.primary)
                }

                statRow(
                    title: "Height",
                    valueText: "\(viewModel.draft.heightInchesValue)",
                    unitText: "inches"
                ) {
                    Picker("Height in inches", selection: $viewModel.draft.heightInchesValue) {
                        ForEach(48...90, id: \.self) { inches in
                            Text("\(inches)").tag(inches)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AltoTheme.primary)
                }

                statRow(
                    title: "Weight",
                    valueText: "\(viewModel.draft.weightLb)",
                    unitText: "lb"
                ) {
                    Picker("Weight in lb", selection: $viewModel.draft.weightLb) {
                        ForEach(70...400, id: \.self) { weight in
                            Text("\(weight)").tag(weight)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AltoTheme.primary)
                }

                if let ageError = viewModel.ageValidationMessage {
                    Text(ageError)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
            .altoCard()

            Text("Your data is encrypted and used only for metabolic calculations.")
                .font(.footnote.italic())
                .foregroundStyle(AltoTheme.textSecondary)
                .altoCard()
        }
    }

    private func statRow<Control: View>(
        title: String,
        valueText: String,
        unitText: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AltoTheme.textSecondary)

            HStack(spacing: 8) {
                Text(valueText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AltoTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AltoTheme.background)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AltoTheme.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(unitText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AltoTheme.textSecondary)

                Spacer()

                control()
            }
        }
    }
}
