import Foundation

enum Gender: String, CaseIterable, Codable, Identifiable {
    case male = "Male"
    case female = "Female"

    var id: String { rawValue }
}

enum HeightUnit: String, CaseIterable, Codable, Identifiable {
    case imperial = "Imperial"
    case metric = "Metric"

    var id: String { rawValue }
}

enum HealthCondition: String, CaseIterable, Codable, Identifiable {
    case asthma = "Asthma"
    case heartCondition = "Heart Condition"
    case joints = "Joint Issues"
    case diabetes = "Diabetes"
    case other = "Other"

    var id: String { rawValue }
}

enum ActivityPreset: String, CaseIterable, Codable, Identifiable {
    case custom = "Custom"
    case notVeryActive = "Not Very Active"
    case neverWorkout = "Never Workout"

    var id: String { rawValue }
}

enum ActivityFrequencyUnit: String, CaseIterable, Codable, Identifiable {
    case weekly = "week"
    case monthly = "month"

    var id: String { rawValue }
}

enum WorkoutPreference: String, CaseIterable, Codable, Identifiable {
    case pilates = "Pilates"
    case yoga = "Yoga"
    case hiit = "HIIT"
    case running = "Running"
    case rowing = "Rowing"

    var id: String { rawValue }
}

enum GoalTimelineUnit: String, CaseIterable, Codable, Identifiable {
    case weeks = "weeks"
    case months = "months"

    var id: String { rawValue }
}

enum MilestonePhase: String, CaseIterable, Codable, Identifiable {
    case base = "Base"
    case build = "Build"
    case peak = "Peak"
    case taper = "Taper"

    var id: String { rawValue }
}

struct UserProfileDraft {
    var name: String = ""
    var gender: Gender = .male
    var age: Int = 25
    var heightInchesValue: Int = 68
    var weightLb: Int = 154
    var selectedConditions: Set<HealthCondition> = []
    var otherConditionText: String = ""
    var activityPreset: ActivityPreset = .custom
    var activityFrequencyUnit: ActivityFrequencyUnit = .weekly
    var activityFrequencyValue: Int = 2
    var preferredWorkouts: Set<WorkoutPreference> = []
    var goalName: String = ""
    var goalTimelineValue: Int = 4
    var goalTimelineUnit: GoalTimelineUnit = .months
    var periodDays: Int = 5
    var cycleLengthDays: Int = 28
    var lastPeriodDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

    var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isAgeValid: Bool {
        age >= 14
    }

    var isCycleDataValid: Bool {
        periodDays >= 1 &&
        cycleLengthDays >= 20 &&
        cycleLengthDays <= 40 &&
        lastPeriodDate <= Date()
    }

    var isActivityValid: Bool {
        if activityPreset == .custom {
            return activityFrequencyValue >= 0
        }
        return true
    }

    var isGoalValid: Bool {
        !goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && goalTimelineValue > 0
    }

    var activitySummary: String {
        switch activityPreset {
        case .notVeryActive:
            return "Not very active"
        case .neverWorkout:
            return "Never workout"
        case .custom:
            let plural = activityFrequencyValue == 1 ? "time" : "times"
            return "\(activityFrequencyValue) \(plural) / \(activityFrequencyUnit.rawValue)"
        }
    }

    var heightInCentimeters: Double {
        Double(heightInchesValue) * 2.54
    }
}

struct UserProfileRecord: Encodable {
    let name: String
    let gender: String
    let age: Int
    let heightCm: Double
    let heightUnit: String
    let weightLb: Int
    let healthConditions: [String]
    let otherConditionText: String?
    let activityPreset: String
    let activityFrequencyUnit: String?
    let activityFrequencyValue: Int?
    let preferredWorkouts: [String]
    let goalName: String
    let goalTimelineValue: Int
    let goalTimelineUnit: String
    let periodDays: Int?
    let cycleLengthDays: Int?
    let lastPeriodDate: Date?
}

struct GoalMilestone: Identifiable {
    let id = UUID()
    let phase: MilestonePhase
    let startDate: Date
    let endDate: Date
}
