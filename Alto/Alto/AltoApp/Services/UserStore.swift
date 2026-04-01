import Foundation

@MainActor
final class UserStore: ObservableObject {
    static let shared = UserStore()
    private let defaults = UserDefaults.standard

    @Published var isOnboardingComplete: Bool
    @Published var userName: String
    @Published var age: Int
    @Published var weightLb: Int
    @Published var heightInchesValue: Int
    @Published var gender: String
    @Published var healthConditions: [String]
    @Published var activityFrequencyValue: Int
    @Published var activityFrequencyUnit: String
    @Published var preferredWorkouts: [String]
    @Published var goalName: String
    @Published var goalTimelineValue: Int
    @Published var goalTimelineUnit: String
    @Published var goalStartDate: Date
    @Published var lastSentinelDate: Date?

    init() {
        isOnboardingComplete = defaults.bool(forKey: "isOnboardingComplete")
        userName = defaults.string(forKey: "userName") ?? "Athlete"
        age = defaults.integer(forKey: "age") == 0 ? 25 : defaults.integer(forKey: "age")
        weightLb = defaults.integer(forKey: "weightLb") == 0 ? 154 : defaults.integer(forKey: "weightLb")
        heightInchesValue = defaults.integer(forKey: "heightInchesValue") == 0 ? 68 : defaults.integer(forKey: "heightInchesValue")
        gender = defaults.string(forKey: "gender") ?? "Male"
        healthConditions = defaults.stringArray(forKey: "healthConditions") ?? []
        activityFrequencyValue = defaults.integer(forKey: "activityFrequencyValue") == 0 ? 3 : defaults.integer(forKey: "activityFrequencyValue")
        activityFrequencyUnit = defaults.string(forKey: "activityFrequencyUnit") ?? "week"
        preferredWorkouts = defaults.stringArray(forKey: "preferredWorkouts") ?? []
        goalName = defaults.string(forKey: "goalName") ?? "My Fitness Goal"
        goalTimelineValue = defaults.integer(forKey: "goalTimelineValue") == 0 ? 4 : defaults.integer(forKey: "goalTimelineValue")
        goalTimelineUnit = defaults.string(forKey: "goalTimelineUnit") ?? "months"
        goalStartDate = defaults.object(forKey: "goalStartDate") as? Date ?? Date()
        lastSentinelDate = defaults.object(forKey: "lastSentinelDate") as? Date
    }

    func save(from record: UserProfileRecord) {
        userName = record.name
        age = record.age
        weightLb = record.weightLb
        heightInchesValue = Int(record.heightCm / 2.54)
        gender = record.gender
        healthConditions = record.healthConditions
        activityFrequencyValue = record.activityFrequencyValue ?? 3
        activityFrequencyUnit = record.activityFrequencyUnit ?? "week"
        preferredWorkouts = record.preferredWorkouts
        goalName = record.goalName
        goalTimelineValue = record.goalTimelineValue
        goalTimelineUnit = record.goalTimelineUnit
        goalStartDate = Date()
        isOnboardingComplete = true
        persist()
    }

    func markSentinelComplete() {
        lastSentinelDate = Date()
        defaults.set(lastSentinelDate, forKey: "lastSentinelDate")
    }

    var needsDailySentinel: Bool {
        guard let last = lastSentinelDate else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    var goalTargetDate: Date {
        let calendar = Calendar.current
        if goalTimelineUnit == "weeks" {
            return calendar.date(byAdding: .weekOfYear, value: goalTimelineValue, to: goalStartDate) ?? goalStartDate
        } else {
            return calendar.date(byAdding: .month, value: goalTimelineValue, to: goalStartDate) ?? goalStartDate
        }
    }

    var currentGoalPhase: GoalPhase {
        let milestones = GoalTimelineGenerator.generate(targetDate: goalTargetDate, from: goalStartDate)
        let today = Date()
        for milestone in milestones {
            if today >= milestone.startDate && today <= milestone.endDate {
                return bridgePhase(milestone.phase)
            }
        }
        // Default: if past end, taper; if before start, base
        if today < goalStartDate {
            return .base
        }
        return .taper
    }

    var goalProgressFraction: Double {
        let total = goalTargetDate.timeIntervalSince(goalStartDate)
        guard total > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(goalStartDate)
        return max(0, min(1, elapsed / total))
    }

    var daysUntilGoal: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: goalTargetDate).day ?? 0)
    }

    var heightFeetDisplay: String {
        let feet = heightInchesValue / 12
        let inches = heightInchesValue % 12
        return "\(feet)'\(inches)\""
    }

    /// Human-readable activity level for the orchestration prompt
    var activityPreset: String {
        "\(activityFrequencyValue)× per \(activityFrequencyUnit)"
    }

    /// Alias for preferred workouts — used by ClaudeOrchestrationService
    var workoutPreferences: [String] { preferredWorkouts }

    private func bridgePhase(_ milestone: MilestonePhase) -> GoalPhase {
        switch milestone {
        case .base: return .base
        case .build: return .build
        case .peak: return .peak
        case .taper: return .taper
        }
    }

    private func persist() {
        defaults.set(isOnboardingComplete, forKey: "isOnboardingComplete")
        defaults.set(userName, forKey: "userName")
        defaults.set(age, forKey: "age")
        defaults.set(weightLb, forKey: "weightLb")
        defaults.set(heightInchesValue, forKey: "heightInchesValue")
        defaults.set(gender, forKey: "gender")
        defaults.set(healthConditions, forKey: "healthConditions")
        defaults.set(activityFrequencyValue, forKey: "activityFrequencyValue")
        defaults.set(activityFrequencyUnit, forKey: "activityFrequencyUnit")
        defaults.set(preferredWorkouts, forKey: "preferredWorkouts")
        defaults.set(goalName, forKey: "goalName")
        defaults.set(goalTimelineValue, forKey: "goalTimelineValue")
        defaults.set(goalTimelineUnit, forKey: "goalTimelineUnit")
        defaults.set(goalStartDate, forKey: "goalStartDate")
    }
}
