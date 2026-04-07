import SwiftUI

struct CycleDetailsView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeaderView(
                stepIndex: 6,
                totalSteps: viewModel.totalSteps,
                title: "Cycle Details",
                subtitle: "Optional female health inputs for safer training recommendations."
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Period days")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AltoTheme.primary)
                Picker("Period days", selection: $viewModel.draft.periodDays) {
                    ForEach(1...10, id: \.self) { day in
                        Text("\(day) days").tag(day)
                    }
                }
                .pickerStyle(.menu)
                .tint(AltoTheme.primary)

                Text("Cycle length")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AltoTheme.primary)
                Picker("Cycle length", selection: $viewModel.draft.cycleLengthDays) {
                    ForEach(20...40, id: \.self) { day in
                        Text("\(day) days").tag(day)
                    }
                }
                .pickerStyle(.menu)
                .tint(AltoTheme.primary)

                DatePicker(
                    "Last period date",
                    selection: $viewModel.draft.lastPeriodDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .tint(AltoTheme.primary)
            }
            .altoCard()

            if let message = viewModel.cycleValidationMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
    }
}
