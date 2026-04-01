import SwiftUI

struct SentinelPopupView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var userStore: UserStore

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Good morning, \(userStore.userName) 👋")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(AltoTheme.textPrimary)
                    Text("Quick check-in — how does your body feel? This shapes your readiness score.")
                        .font(.system(size: 14))
                        .foregroundStyle(AltoTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Soreness
                wellnessRow(
                    label: "Soreness",
                    emoji: "😴",
                    value: $viewModel.sorenessScore,
                    descriptions: ["None at all", "Slightly sore", "Moderately sore", "Very sore", "Extremely sore"]
                )

                // Stress
                wellnessRow(
                    label: "Stress",
                    emoji: "🧠",
                    value: $viewModel.stressScore,
                    descriptions: ["No stress", "Manageable", "Noticeable", "High stress", "Overwhelmed"]
                )

                // Motivation
                wellnessRow(
                    label: "Motivation",
                    emoji: "💪",
                    value: $viewModel.motivationScore,
                    descriptions: ["None at all", "Low", "Moderate", "Feeling pumped!", "Unstoppable! 🔥"]
                )

                // Submit button
                Button("See My Readiness Score →") {
                    viewModel.dismissSentinel()
                }
                .buttonStyle(AltoPrimaryButtonStyle())
            }
            .padding(24)
            .background(AltoTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AltoTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 20)
            .frame(maxWidth: 400)
        }
    }

    @ViewBuilder
    private func wellnessRow(
        label: String,
        emoji: String,
        value: Binding<Int>,
        descriptions: [String]
    ) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(emoji) \(label)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AltoTheme.textPrimary)
                Spacer()
                Text(value.wrappedValue > 0 ? "\(value.wrappedValue) / 5 • \(descriptions[value.wrappedValue - 1])" : "Tap to rate")
                    .font(.system(size: 12))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
            SegmentedBar(value: value)
        }
    }
}

struct SegmentedBar: View {
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...5, id: \.self) { i in
                Capsule()
                    .fill(i <= value ? AltoTheme.primary.opacity(segOpacity(i)) : AltoTheme.border)
                    .frame(maxWidth: .infinity)
                    .frame(height: 14)
                    .onTapGesture {
                        value = (value == i) ? 0 : i
                    }
                    .animation(.easeInOut(duration: 0.15), value: value)
            }
        }
    }

    private func segOpacity(_ i: Int) -> Double {
        [0.3, 0.5, 0.65, 0.82, 1.0][i - 1]
    }
}
