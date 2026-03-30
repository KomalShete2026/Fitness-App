import Foundation

struct DailyProjection: Identifiable {
    let id = UUID()
    let date: Date
    let projectedSleepHours: Double
    let precipitationProbability: Double

    var isHighReadiness: Bool {
        projectedSleepHours >= 6.5 && precipitationProbability <= 0.5
    }
}

struct PlannedWorkout: Identifiable {
    let id = UUID()
    let name: String
    let intensity: WorkoutIntensity
    var scheduledDate: Date
}

enum WorkoutIntensity {
    case easy
    case hard
}

struct PivotDecision {
    let shouldPivot: Bool
    let reasons: [String]

    var whyText: String {
        if reasons.isEmpty { return "No pivot needed." }
        return reasons.joined(separator: " ")
    }
}
