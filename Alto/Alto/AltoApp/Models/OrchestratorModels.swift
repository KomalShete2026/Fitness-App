import Foundation

enum DailyMood: String, CaseIterable, Identifiable {
    case readyToPush = "Ready to Push"
    case balanced = "Balanced"
    case lowEnergy = "Low Energy"
    case muscleFatigue = "Muscle Fatigue"
    case mentallyDrained = "Mentally Drained"
    case needRecovery = "Need Recovery"

    var id: String { rawValue }
}

enum CyclePhase: String, CaseIterable {
    case follicular = "Follicular"
    case ovulatory = "Ovulatory"
    case luteal = "Luteal"
    case menstrual = "Menstrual"
    case unknown = "Unknown"
}

enum WeatherImpact {
    case clear
    case rain
    case extreme
}

enum GoalPhase: String, CaseIterable {
    case base = "Base"
    case build = "Build"
    case peak = "Peak"
    case taper = "Taper"
}

enum TaskLocation {
    case outdoor
    case indoor
}

struct PlannedTask {
    var name: String
    var durationMinutes: Int
    var location: TaskLocation
    var targetRPE: Int
    var plannedBurn: Double
}

struct DailyReadiness {
    // 1 (worst) -> 5 (best)
    let soreness: Int
    let stress: Int
    let mood: Int
    let cyclePhase: CyclePhase
}

struct ReadinessScore {
    let score: Int
    let reasons: [String]
}

struct DailySentinelQuestion: Identifiable {
    let id = UUID()
    let title: String
    let scaleMinLabel: String
    let scaleMaxLabel: String
}

struct OnboardingAuditInput {
    let goalName: String
    let targetDate: Date
    let today: Date
    let currentWeeklyVolume: Double
    let requiredWeeklyVolumeAtDeadline: Double
}

struct OnboardingAuditResult {
    let isFeasible: Bool
    let requiredWeeklyIncreasePercent: Double
    let injuryRiskPercent: Int?
    let recommendedExtensionWeeks: Int?
    let honestFeedback: String?
}

struct EffortGapEvaluation {
    let achievedRatio: Double
    let triggerCompassionateReengagement: Bool
    let triggerRecoveryDay: Bool
    let message: String
}

enum NotificationScenario {
    case compassionateReengagement
    case deepRecoveryInserted
}

struct OrchestratorContext {
    let mood: DailyMood
    let sleepHours: Double?
    let rainProbability: Double?
    let activityPreset: String
    let goalName: String
    let goalPhase: GoalPhase
    let readiness: DailyReadiness?
    let weatherImpact: WeatherImpact

    init(
        mood: DailyMood,
        sleepHours: Double?,
        rainProbability: Double?,
        activityPreset: String,
        goalName: String,
        goalPhase: GoalPhase,
        readiness: DailyReadiness? = nil,
        weatherImpact: WeatherImpact = .clear
    ) {
        self.mood = mood
        self.sleepHours = sleepHours
        self.rainProbability = rainProbability
        self.activityPreset = activityPreset
        self.goalName = goalName
        self.goalPhase = goalPhase
        self.readiness = readiness
        self.weatherImpact = weatherImpact
    }
}

struct OrchestratedAction: Identifiable {
    let id = UUID()
    let title: String
    let details: String
}

struct OrchestratedPlan {
    let headline: String
    let why: String
    let workoutName: String
    let workoutDurationMinutes: Int
    let actions: [OrchestratedAction]
    let shouldPivot: Bool
}
