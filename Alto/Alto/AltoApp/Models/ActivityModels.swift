import Foundation

enum ActivityStatus {
    case notStarted, inProgress, done
}

struct PlannedActivity: Identifiable {
    var id: UUID
    let name: String
    let emoji: String
    let durationMinutes: Int
    let targetCalories: Double
    let details: String
    var status: ActivityStatus
    var actualCalories: Double?

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        durationMinutes: Int,
        targetCalories: Double,
        details: String = "",
        status: ActivityStatus = .notStarted
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.durationMinutes = durationMinutes
        self.targetCalories = targetCalories
        self.details = details
        self.status = status
        self.actualCalories = nil
    }
}

struct TodayPlan {
    var activities: [PlannedActivity]
    let calorieGoal: Double

    var doneActivities: [PlannedActivity] { activities.filter { $0.status == .done } }
    var nextActivity: PlannedActivity? { activities.first { $0.status == .notStarted } }
    var currentActivity: PlannedActivity? { activities.first { $0.status == .inProgress } }
    var totalCaloriesBurned: Double { doneActivities.reduce(0) { $0 + ($1.actualCalories ?? $1.targetCalories) } }
    var doneCount: Int { doneActivities.count }
    var totalCount: Int { activities.count }
    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(doneCount) / Double(totalCount)
    }
    var summaryText: String { "\(doneCount) of \(totalCount) done" }

    static let empty = TodayPlan(activities: [], calorieGoal: 500)
}
