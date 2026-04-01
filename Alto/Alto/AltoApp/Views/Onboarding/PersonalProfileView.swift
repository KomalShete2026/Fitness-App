import SwiftUI

struct PersonalProfileView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {

            // Decorative fitness silhouette — replace with Image("fitness_woman_bg")
            // in Assets.xcassets for a photo-realistic look
            Image(systemName: "figure.run")
                .font(.system(size: 220))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AltoTheme.primary.opacity(0.11),
                            AltoTheme.primary.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(x: 55, y: -8)
                .allowsHitTesting(false)

            VStack(spacing: 16) {
                StepHeaderView(
                    stepIndex: 1,
                    totalSteps: viewModel.totalSteps,
                    title: "Your Identity",
                    subtitle: "A few basics to personalize your training plan."
                )

                // Full Name
                VStack(alignment: .leading, spacing: 8) {
                    requiredLabel("FULL NAME")
                    TextField("e.g. Alex Rivera", text: $viewModel.draft.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .padding(12)
                        .background(AltoTheme.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AltoTheme.border, lineWidth: 1)
                        )
                        .foregroundStyle(AltoTheme.textPrimary)
                }
                .altoCard()

                // Gender
                VStack(alignment: .leading, spacing: 10) {
                    requiredLabel("GENDER")
                    HStack(spacing: 10) {
                        ForEach(Gender.allCases) { gender in
                            genderButton(gender)
                        }
                    }
                }
                .altoCard()

                // Body Stats
                VStack(alignment: .leading, spacing: 0) {
                    requiredLabel("BODY STATS")
                    Spacer().frame(height: 14)

                    statRow(label: "Age", value: $viewModel.draft.age, unit: "yrs", range: 10...99)

                    if let ageError = viewModel.ageValidationMessage {
                        Text(ageError)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.top, 6)
                    }

                    rowDivider()

                    statRow(label: "Height", value: $viewModel.draft.heightInchesValue, unit: "in", range: 48...90)

                    rowDivider()

                    statRow(label: "Weight", value: $viewModel.draft.weightLb, unit: "lb", range: 70...400)
                }
                .altoCard()

                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text("Encrypted and used only for personalization.")
                        .font(.footnote)
                }
                .foregroundStyle(AltoTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: – Components

    @ViewBuilder
    private func requiredLabel(_ text: String) -> some View {
        HStack(spacing: 2) {
            Text(text)
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(AltoTheme.primary)
            Text("*")
                .font(.caption.weight(.bold))
                .foregroundStyle(AltoTheme.primary)
        }
    }

    @ViewBuilder
    private func genderButton(_ gender: Gender) -> some View {
        let isSelected = viewModel.draft.gender == gender
        Button { viewModel.updateGender(gender) } label: {
            Text(gender.rawValue)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(isSelected ? AltoTheme.primary : AltoTheme.textSecondary)
                .background(isSelected ? AltoTheme.primary.opacity(0.12) : AltoTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? AltoTheme.primary : AltoTheme.border, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    @ViewBuilder
    private func rowDivider() -> some View {
        Rectangle()
            .fill(AltoTheme.border)
            .frame(height: 1)
            .padding(.vertical, 14)
    }

    @ViewBuilder
    private func statRow(
        label: String,
        value: Binding<Int>,
        unit: String,
        range: ClosedRange<Int>
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AltoTheme.textPrimary)
                .frame(minWidth: 52, alignment: .leading)

            Spacer()

            // − value + stepper
            HStack(spacing: 0) {
                Button {
                    let next = value.wrappedValue - 1
                    if range.contains(next) { value.wrappedValue = next }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .frame(width: 34, height: 36)
                        .foregroundStyle(AltoTheme.textSecondary)
                        .background(AltoTheme.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AltoTheme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Text("\(value.wrappedValue)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AltoTheme.textPrimary)
                    .frame(width: 52)
                    .multilineTextAlignment(.center)

                Button {
                    let next = value.wrappedValue + 1
                    if range.contains(next) { value.wrappedValue = next }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 34, height: 36)
                        .foregroundStyle(AltoTheme.primary)
                        .background(AltoTheme.primary.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AltoTheme.primary.opacity(0.4), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Text(unit)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AltoTheme.textSecondary)
                .frame(width: 28, alignment: .leading)
        }
    }
}
