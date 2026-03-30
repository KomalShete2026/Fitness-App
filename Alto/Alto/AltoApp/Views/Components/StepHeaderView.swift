import SwiftUI

struct StepHeaderView: View {
    let stepIndex: Int
    let totalSteps: Int
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ForEach(1...max(totalSteps, 1), id: \.self) { index in
                    Capsule()
                        .fill(index <= stepIndex ? AltoTheme.primary : AltoTheme.border)
                        .frame(height: 4)
                }
            }

            Text("Step \(stepIndex): \(title)")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(AltoTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundStyle(AltoTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
