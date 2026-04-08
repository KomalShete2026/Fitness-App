import SwiftUI

struct GoalProgressView: View {
    @ObservedObject var viewModel: GoalProgressViewModel
    @State private var expandedPhase: GoalPhase? = nil
    @State private var animateProgress: Bool = false

    private let phases: [GoalPhase] = [.base, .build, .peak, .taper]

    var body: some View {
        ZStack {
            AltoTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    overallProgressCard
                    journeyCard
                    addGoalButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateProgress = true
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Goals 🎯")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(AltoTheme.textPrimary)
                Text("Your training roadmap.")
                    .font(.system(size: 13))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
            Spacer()
            // Days away badge
            VStack(spacing: 2) {
                Text("\(viewModel.daysUntilGoal)")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(viewModel.daysUntilGoal < 30 ? AltoTheme.red : AltoTheme.primary)
                Text("days left")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
        }
        .padding(18)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Overall Progress

    private var overallProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.goalName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AltoTheme.textPrimary)
                    Text("\(viewModel.currentPhase.rawValue) Phase · \(viewModel.weeksRemaining) weeks remaining")
                        .font(.system(size: 12))
                        .foregroundStyle(AltoTheme.textSecondary)
                }
                Spacer()
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(AltoTheme.primary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AltoTheme.border)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [AltoTheme.primary.opacity(0.7), AltoTheme.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (animateProgress ? viewModel.overallProgress : 0), height: 10)

                    // Current position indicator
                    Circle()
                        .fill(AltoTheme.primary)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(AltoTheme.background, lineWidth: 2))
                        .offset(x: geo.size.width * (animateProgress ? viewModel.overallProgress : 0) - 8)
                }
            }
            .frame(height: 16)

            // Phase tick marks
            HStack(spacing: 0) {
                ForEach(phases, id: \.rawValue) { phase in
                    Text(phase.rawValue)
                        .font(.system(size: 10, weight: viewModel.currentPhase == phase ? .bold : .regular))
                        .foregroundStyle(viewModel.currentPhase == phase ? AltoTheme.primary : AltoTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Journey Path Card

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AltoTheme.primary)
                Text("JOURNEY PATH")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AltoTheme.primary)
            }
            .padding(.bottom, 16)

            // Start node
            journeyEndpoint(
                emoji: "🚩",
                label: "START",
                date: viewModel.goalStartDate,
                color: AltoTheme.green,
                isBottom: false
            )

            // Phase nodes
            ForEach(Array(phases.enumerated()), id: \.element.rawValue) { index, phase in
                phaseNode(phase: phase, isLast: index == phases.count - 1)
            }

            // Finish node
            journeyEndpoint(
                emoji: "🏆",
                label: "FINISH LINE",
                date: viewModel.goalTargetDate,
                color: AltoTheme.primary,
                isBottom: true
            )
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Journey Endpoint (Start / Finish)

    private func journeyEndpoint(emoji: String, label: String, date: Date, color: Color, isBottom: Bool) -> some View {
        HStack(spacing: 0) {
            // Node column
            VStack(spacing: 0) {
                if isBottom {
                    connectorLine(filled: true)
                }
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Circle()
                        .stroke(color.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 44, height: 44)
                    Text(emoji)
                        .font(.system(size: 20))
                }
                if !isBottom {
                    connectorLine(filled: viewModel.status(for: .base) != .upcoming)
                }
            }
            .frame(width: 60)

            // Label
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(color)
                Text(formatDate(date))
                    .font(.system(size: 12))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
            .padding(.leading, 8)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Phase Node

    @ViewBuilder
    private func phaseNode(phase: GoalPhase, isLast: Bool) -> some View {
        let status = viewModel.status(for: phase)
        let milestone = viewModel.milestone(for: phase)
        let isExpanded = expandedPhase == phase

        HStack(alignment: .top, spacing: 0) {
            // Node column
            VStack(spacing: 0) {
                connectorLine(filled: status != .upcoming)

                ZStack {
                    // Pulse ring for current phase
                    if status == .current {
                        PulsingRing(color: AltoTheme.primary)
                            .frame(width: 52, height: 52)
                    }

                    Circle()
                        .fill(nodeBackground(status))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle().stroke(nodeBorder(status), lineWidth: status == .current ? 2 : 1)
                        )

                    Text(phaseEmoji(phase))
                        .font(.system(size: 18))
                        .opacity(status == .upcoming ? 0.4 : 1)
                }

                connectorLine(filled: status == .completed)
            }
            .frame(width: 60)

            // Phase card
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedPhase = (expandedPhase == phase) ? nil : phase
                }
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    // Phase header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(phase.rawValue.uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundStyle(status == .upcoming ? AltoTheme.textSecondary : AltoTheme.textPrimary)

                                if status == .current {
                                    Text("YOU ARE HERE")
                                        .font(.system(size: 9, weight: .bold))
                                        .tracking(0.8)
                                        .foregroundStyle(AltoTheme.primary)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(AltoTheme.primary.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }

                            if let m = milestone {
                                Text("\(formatDate(m.startDate)) – \(formatDate(m.endDate))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AltoTheme.textSecondary)
                            }
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            statusChip(status)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AltoTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.trailing, 4)

                    // Expanded content
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 10) {
                            Divider().background(AltoTheme.border)

                            Text(viewModel.description(for: phase))
                                .font(.system(size: 13))
                                .foregroundStyle(AltoTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AltoTheme.primary)
                                Text(viewModel.weeklyFocus(for: phase))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AltoTheme.textSecondary)
                            }

                            if status == .current {
                                phaseProgressBar
                            }
                        }
                        .padding(.bottom, 14)
                        .padding(.trailing, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var phaseProgressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Phase progress")
                    .font(.system(size: 11))
                    .foregroundStyle(AltoTheme.textSecondary)
                Spacer()
                Text("\(Int(viewModel.phaseProgressFraction * 100))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AltoTheme.primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AltoTheme.border)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AltoTheme.primary)
                        .frame(width: geo.size.width * (animateProgress ? viewModel.phaseProgressFraction : 0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(10)
        .background(AltoTheme.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Connector Line

    private func connectorLine(filled: Bool) -> some View {
        Rectangle()
            .fill(filled ? AltoTheme.primary.opacity(0.6) : AltoTheme.border)
            .frame(width: 3, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    // MARK: - Add Goal Button

    private var addGoalButton: some View {
        Button { } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
                Text("Add Another Goal")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(AltoTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AltoTheme.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
    }

    // MARK: - Helpers

    private func phaseEmoji(_ phase: GoalPhase) -> String {
        switch phase {
        case .base:  return "🏗️"
        case .build: return "📈"
        case .peak:  return "🔥"
        case .taper: return "🧘"
        }
    }

    private func nodeBackground(_ status: PhaseStatus) -> Color {
        switch status {
        case .completed: return AltoTheme.green.opacity(0.15)
        case .current:   return AltoTheme.primary.opacity(0.15)
        case .upcoming:  return AltoTheme.surface
        }
    }

    private func nodeBorder(_ status: PhaseStatus) -> Color {
        switch status {
        case .completed: return AltoTheme.green.opacity(0.6)
        case .current:   return AltoTheme.primary
        case .upcoming:  return AltoTheme.border
        }
    }

    @ViewBuilder
    private func statusChip(_ status: PhaseStatus) -> some View {
        switch status {
        case .completed:
            Text("✓ Done")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AltoTheme.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AltoTheme.green.opacity(0.12))
                .clipShape(Capsule())
        case .current:
            EmptyView()
        case .upcoming:
            Text("Upcoming")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AltoTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AltoTheme.border.opacity(0.4))
                .clipShape(Capsule())
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}

// MARK: - Pulsing Ring

struct PulsingRing: View {
    let color: Color
    @State private var animate = false

    var body: some View {
        Circle()
            .stroke(color.opacity(animate ? 0 : 0.4), lineWidth: animate ? 0 : 6)
            .scaleEffect(animate ? 1.4 : 1.0)
            .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: animate)
            .onAppear { animate = true }
    }
}
