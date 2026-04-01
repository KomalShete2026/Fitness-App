import Foundation

enum PhaseStatus {
    case completed, current, upcoming
}

@MainActor
final class GoalProgressViewModel: ObservableObject {
    private let userStore: UserStore
    @Published var milestones: [GoalMilestone] = []
    @Published var sessionsCompleted: Int = 24

    init(userStore: UserStore) {
        self.userStore = userStore
        refresh()
    }

    func refresh() {
        milestones = GoalTimelineGenerator.generate(
            targetDate: userStore.goalTargetDate,
            from: userStore.goalStartDate
        )
    }

    var currentPhase: GoalPhase { userStore.currentGoalPhase }
    var overallProgress: Double { userStore.goalProgressFraction }
    var daysUntilGoal: Int { userStore.daysUntilGoal }
    var goalName: String { userStore.goalName }
    var goalTargetDate: Date { userStore.goalTargetDate }

    var currentMilestone: GoalMilestone? {
        let today = Date()
        return milestones.first { today >= $0.startDate && today <= $0.endDate }
    }

    var phaseProgressFraction: Double {
        guard let current = currentMilestone else { return 0 }
        let total = current.endDate.timeIntervalSince(current.startDate)
        let elapsed = Date().timeIntervalSince(current.startDate)
        return max(0, min(1, elapsed / total))
    }

    var weeksRemaining: Int {
        max(0, daysUntilGoal / 7)
    }

var goalStartDate: Date { userStore.goalStartDate }

    var goalEmoji: String { "🏅" }

    func status(for phase: GoalPhase) -> PhaseStatus {
        let order: [GoalPhase] = [.base, .build, .peak, .taper]
        guard let ci = order.firstIndex(of: currentPhase),
              let pi = order.firstIndex(of: phase) else { return .upcoming }
        if pi < ci { return .completed }
        if pi == ci { return .current }
        return .upcoming
    }

    func milestone(for phase: GoalPhase) -> GoalMilestone? {
        milestones.first { $0.phase.rawValue == phase.rawValue }
    }

    func description(for phase: GoalPhase) -> String {
        switch phase {
        case .base:  return "Build your aerobic engine with easy runs and mobility. Volume over intensity."
        case .build: return "Layer in tempo efforts and strength work. This is where fitness is made."
        case .peak:  return "Race-specific sessions at goal pace. Maximum sharpness, controlled fatigue."
        case .taper: return "Pull back volume, keep intensity. Arrive at the start line feeling electric."
        }
    }

    func weeklyFocus(for phase: GoalPhase) -> String {
        switch phase {
        case .base:  return "3 easy runs · 2 mobility sessions"
        case .build: return "1 tempo · 1 long run · 1 strength session"
        case .peak:  return "1 race pace · 1 long run · 1 strength session"
        case .taper: return "2 easy shakeouts · 1 strides session"
        }
    }

}
