import Foundation
import SwiftUI
import UIKit

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var sleepHours: Double?
    @Published var temperatureCelsius: Double?
    @Published var precipitationProbability: Double?
    @Published var healthStatusText: String = "Not connected"
    @Published var weatherStatusText: String = "Not loaded"
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var projections: [DailyProjection] = []
    @Published var plannedWorkout: PlannedWorkout
    @Published var pivotAccepted: Bool = false
    @Published var selectedMood: DailyMood = .balanced
    @Published var orchestratedPlan: OrchestratedPlan?
    @Published var readinessScore: Int?
    @Published var readinessReasons: [String] = []
    @Published var sorenessScore: Int = 3
    @Published var stressScore: Int = 3
    @Published var motivationScore: Int = 3
    @Published var selectedCyclePhase: CyclePhase = .unknown
    @Published var activeEnergyBurnedToday: Double?
    @Published var reportedRPE: Int = 5
    @Published var effortGapMessage: String?

    @Published var voiceTranscript: String = ""
    @Published var lastVoiceLog: VoiceWorkoutEntry?
    @Published var pathProgressSessions: Int = 0
    @Published var isDictating: Bool = false
    @Published var selectedMealImage: UIImage?
    @Published var pendingMacroEstimate: MacroEstimate?
    @Published var macroTotals = DailyMacroTotal()
    @Published var isAnalyzingMeal: Bool = false
    @Published var showSentinelPopup: Bool = false
    @Published var todayPlan: TodayPlan = .empty
    @Published var isGeneratingPlan: Bool = false
    @Published var coachNote: String = ""
    @Published var userEnteredActivities: [UserEnteredActivity] = []

    private let healthKitService: HealthKitService
    private let locationService: LocationService
    private let weatherService: WeatherDataService
    private let voiceParser: VoiceWorkoutParsing
    private let speechService: SpeechTranscriptionService
    private let orchestrator: Orchestrating
    private let notificationService: NotificationService
    private let userSettings: UserSettings

    init(
        healthKitService: HealthKitService,
        locationService: LocationService,
        weatherService: WeatherDataService,
        voiceParser: VoiceWorkoutParsing,
        speechService: SpeechTranscriptionService,
        orchestrator: Orchestrating,
        notificationService: NotificationService,
        userSettings: UserSettings
    ) {
        self.healthKitService = healthKitService
        self.locationService = locationService
        self.weatherService = weatherService
        self.voiceParser = voiceParser
        self.speechService = speechService
        self.orchestrator = orchestrator
        self.notificationService = notificationService
        self.userSettings = userSettings
        self.plannedWorkout = PlannedWorkout(
            name: "Tempo Run",
            intensity: .hard,
            scheduledDate: Date()
        )
    }

    var weatherConflict: Bool {
        guard let precipitationProbability else { return false }
        return precipitationProbability > 0.5
    }

    var sleepDisplayText: String {
        guard let sleepHours else { return "No data" }
        return String(format: "%.1f h", sleepHours)
    }

    var weatherDisplayText: String {
        guard let temperatureCelsius else { return "No weather data" }
        return String(format: "%.0f C", temperatureCelsius)
    }

    var precipitationDisplayText: String {
        guard let precipitationProbability else { return "--" }
        return "\(Int((precipitationProbability * 100).rounded()))%"
    }

    var pivotDecision: PivotDecision {
        PivotEngine.evaluate(sleepHours: sleepHours, rainProbability: precipitationProbability)
    }

    var nextHighReadinessDate: Date? {
        let tomorrowStart = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 3600)
        return PivotEngine.nextHighReadinessDate(from: projections, after: tomorrowStart)
    }

    var macroTotalsText: String {
        "\(macroTotals.calories) kcal | P \(Int(macroTotals.proteinGrams))g | C \(Int(macroTotals.carbsGrams))g | F \(Int(macroTotals.fatGrams))g"
    }

    func connectHealthKit() async {
        errorMessage = nil
        pivotAccepted = false
        do {
            try await healthKitService.requestPermissions()
            let sleep = try await healthKitService.fetchLastNightSleepHours()
            sleepHours = sleep
            activeEnergyBurnedToday = try await healthKitService.fetchActiveEnergyBurnedToday()
            healthStatusText = "Connected"
            rebuildProjectionSleep()
            refreshOrchestratedPlan()
        } catch {
            healthStatusText = "Permission needed"
            errorMessage = "HealthKit: \(error.localizedDescription)"
        }
    }

    func refreshWeather() async {
        errorMessage = nil
        pivotAccepted = false
        do {
            let location = try await locationService.requestCurrentLocation()
            let weather = try await weatherService.fetchCurrentWeather(at: location)
            temperatureCelsius = weather.temperatureCelsius
            precipitationProbability = weather.precipitationProbability

            let daily = try await weatherService.fetchDailyPrecipitationForecast(at: location, days: 7)
            projections = buildProjections(from: daily)

            weatherStatusText = "Updated"
            refreshOrchestratedPlan()
        } catch {
            weatherStatusText = "Unavailable"
            errorMessage = "WeatherKit: \(error.localizedDescription)"
        }
    }

    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }

        await connectHealthKit()
        await refreshWeather()
        refreshOrchestratedPlan()
    }

    func acceptPivot() {
        guard pivotDecision.shouldPivot,
              plannedWorkout.intensity == .hard else {
            return
        }

        let fallback = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 3600)
        let newDate = nextHighReadinessDate ?? fallback
        plannedWorkout.scheduledDate = newDate
        pivotAccepted = true
    }

    func parseVoiceLog() {
        errorMessage = nil
        guard let entry = voiceParser.parse(voiceTranscript) else {
            errorMessage = "Voice input could not be parsed. Try: 'I did 30 mins of Yoga'."
            return
        }

        lastVoiceLog = entry
        pathProgressSessions += 1
        voiceTranscript = ""
    }

    func toggleDictation() async {
        errorMessage = nil

        if isDictating {
            speechService.stopTranscription()
            isDictating = false
            return
        }

        let granted = await speechService.requestPermission()
        guard granted else {
            errorMessage = "Speech recognition permission denied."
            return
        }

        do {
            try speechService.startTranscription { [weak self] transcript in
                Task { @MainActor in
                    self?.voiceTranscript = transcript
                }
            }
            isDictating = true
        } catch {
            isDictating = false
            errorMessage = "Voice dictation failed: \(error.localizedDescription)"
        }
    }

    func analyzeSelectedMealImage() async {
        errorMessage = nil
        pendingMacroEstimate = nil

        guard let image = selectedMealImage,
              let jpegData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Capture a meal image first."
            return
        }

        guard userSettings.isAPIKeyConfigured else {
            errorMessage = "Please add your Gemini API key in Profile → Settings."
            return
        }

        isAnalyzingMeal = true
        defer { isAnalyzingMeal = false }

        let macroService = GeminiVisionMacroService(
            apiKey: userSettings.geminiAPIKey,
            model: userSettings.selectedGeminiModel
        )

        do {
            pendingMacroEstimate = try await macroService.analyzeMeal(imageData: jpegData)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmMacros() {
        guard let estimate = pendingMacroEstimate else { return }
        macroTotals.add(estimate)
        pendingMacroEstimate = nil
    }

    func setMood(_ mood: DailyMood) {
        selectedMood = mood
        refreshOrchestratedPlan()
    }

    func scheduleDailySentinelNotification() async {
        do {
            try await notificationService.scheduleDailyWellnessCheck(hour: 7, minute: 0)
        } catch {
            errorMessage = "Notification setup failed: \(error.localizedDescription)"
        }
    }

    func submitDailyWellness() {
        guard let sentinel = orchestrator as? SentinelOrchestrator else { return }

        let readiness = DailyReadiness(
            soreness: sorenessScore,
            stress: stressScore,
            mood: motivationScore,
            cyclePhase: selectedCyclePhase
        )
        let score = sentinel.readinessScore(from: readiness)
        readinessScore = score.score
        readinessReasons = score.reasons
        refreshOrchestratedPlan(with: readiness)
    }

    func evaluatePostWorkout() {
        guard let sentinel = orchestrator as? SentinelOrchestrator else { return }

        let plannedBurn = todayPlan.calorieGoal > 0 ? todayPlan.calorieGoal : 500.0
        let targetRPE = orchestratedPlan?.shouldPivot == true ? 4 : 6
        let achieved = activeEnergyBurnedToday ?? todayPlan.totalCaloriesBurned

        let evaluation = sentinel.evaluateEffortGap(
            activeEnergyBurned: achieved,
            plannedBurn: plannedBurn,
            targetRPE: targetRPE,
            reportedRPE: reportedRPE
        )

        effortGapMessage = evaluation.message

        Task {
            if evaluation.triggerRecoveryDay {
                await notificationService.sendRecoveryDayInserted()
            } else if evaluation.triggerCompassionateReengagement {
                await notificationService.sendCompassionateReengagement(
                    achievedKcal: achieved,
                    plannedKcal: plannedBurn
                )
            }
        }
    }

    func completeWorkoutSession() {
        completeCurrentActivity()
        Task {
            await notificationService.schedulePostWorkoutRPEPrompt(delayMinutes: 10)
        }
    }

    func stopDictationIfNeeded() {
        guard isDictating else { return }
        speechService.stopTranscription()
        isDictating = false
    }

    func onAppear() async {
        showSentinelPopup = UserStore.shared.needsDailySentinel
        await loadDashboard()
        generateTodayPlan()
    }

    func dismissSentinel() {
        submitDailyWellness()
        UserStore.shared.markSentinelComplete()
        withAnimation(.spring(response: 0.35)) { showSentinelPopup = false }
        Task { await generateTodayPlanWithClaude() }
    }

    func setUserEnteredActivities(_ activities: [UserEnteredActivity]) {
        userEnteredActivities = activities
    }

    func startCurrentActivity() {
        guard let idx = todayPlan.activities.firstIndex(where: { $0.status == .notStarted }) else { return }
        todayPlan.activities[idx].status = .inProgress
    }

    func completeCurrentActivity() {
        guard let idx = todayPlan.activities.firstIndex(where: { $0.status == .inProgress }) else { return }
        todayPlan.activities[idx].status = .done
        todayPlan.activities[idx].actualCalories = todayPlan.activities[idx].targetCalories
    }

    func generateTodayPlan() {
        // Synchronous fallback — used when Claude is unavailable
        if let plan = orchestratedPlan, !plan.plannedActivities.isEmpty {
            todayPlan = TodayPlan(
                activities: plan.plannedActivities,
                calorieGoal: Double(plan.calorieTarget)
            )
            coachNote = plan.coachNote
        } else if let plan = orchestratedPlan {
            let emoji = workoutEmoji(for: plan.workoutName)
            let calories = Double(plan.workoutDurationMinutes) * (plan.shouldPivot ? 5.0 : 8.5)
            todayPlan = TodayPlan(
                activities: [PlannedActivity(
                    name: plan.workoutName, emoji: emoji,
                    durationMinutes: plan.workoutDurationMinutes,
                    targetCalories: calories,
                    details: plan.why
                )],
                calorieGoal: calories
            )
        } else {
            todayPlan = defaultPlan(for: UserStore.shared.currentGoalPhase)
        }
    }

    func generateTodayPlanWithClaude() async {
        guard userSettings.isAPIKeyConfigured else {
            // No API key configured — fall back to rule-based
            generateTodayPlan()
            return
        }

        isGeneratingPlan = true
        defer { isGeneratingPlan = false }

        let claude = ClaudeOrchestrationService(
            apiKey: userSettings.geminiAPIKey,
            model: userSettings.selectedGeminiModel
        )

        let readiness = DailyReadiness(
            soreness: sorenessScore,
            stress: stressScore,
            mood: motivationScore,
            cyclePhase: selectedCyclePhase
        )

        let store = UserStore.shared
        let context = OrchestratorContext(
            mood: selectedMood,
            sleepHours: sleepHours,
            rainProbability: precipitationProbability,
            temperatureCelsius: temperatureCelsius,
            activityPreset: store.activityPreset,
            goalName: store.goalName.isEmpty ? "Training Goal" : store.goalName,
            goalPhase: store.currentGoalPhase,
            readiness: readiness,
            weatherImpact: (precipitationProbability ?? 0) > 0.6 ? .rain : .clear,
            healthConditions: store.healthConditions,
            workoutPreferences: store.workoutPreferences,
            calorieTarget: 400
        )

        do {
            let plan = try await claude.buildPlanAsync(
                context: context,
                userEnteredActivities: userEnteredActivities
            )
            orchestratedPlan = plan
            todayPlan = TodayPlan(
                activities: plan.plannedActivities,
                calorieGoal: Double(plan.calorieTarget)
            )
            coachNote = plan.coachNote
            if let readinessScore = plan.readinessSummary.isEmpty ? nil : plan.readinessSummary as String? {
                _ = readinessScore // surfaced via coachNote / headline in UI
            }
        } catch {
            errorMessage = error.localizedDescription
            generateTodayPlan()
        }
    }

    private func workoutEmoji(for name: String) -> String {
        let l = name.lowercased()
        if l.contains("run") || l.contains("tempo") || l.contains("interval") { return "🏃" }
        if l.contains("strength") || l.contains("weight") || l.contains("circuit") { return "🏋️" }
        if l.contains("yoga") || l.contains("mobility") || l.contains("stretch") { return "🧘" }
        if l.contains("rest") || l.contains("walk") { return "🚶" }
        if l.contains("row") { return "🚣" }
        if l.contains("race") { return "🏅" }
        return "💪"
    }

    private func defaultPlan(for phase: GoalPhase) -> TodayPlan {
        switch phase {
        case .base:
            return TodayPlan(activities: [
                PlannedActivity(name: "Easy Run", emoji: "🏃", durationMinutes: 30, targetCalories: 280, details: "Zone 2 aerobic base building"),
                PlannedActivity(name: "Mobility", emoji: "🧘", durationMinutes: 15, targetCalories: 60, details: "Hip flexors and hamstrings")
            ], calorieGoal: 340)
        case .build:
            return TodayPlan(activities: [
                PlannedActivity(name: "Tempo Run", emoji: "⏱️", durationMinutes: 45, targetCalories: 420, details: "Warm-up 10 min → 3×8 min tempo → Cool-down"),
                PlannedActivity(name: "Core Training", emoji: "🏋️", durationMinutes: 20, targetCalories: 100, details: "Plank, dead bug, Russian twists")
            ], calorieGoal: 520)
        case .peak:
            return TodayPlan(activities: [
                PlannedActivity(name: "Race Pace Run", emoji: "🏅", durationMinutes: 50, targetCalories: 550, details: "4×10 min at race pace with 2 min recovery"),
                PlannedActivity(name: "Strength", emoji: "🏋️", durationMinutes: 25, targetCalories: 150, details: "Race-specific strength work")
            ], calorieGoal: 700)
        case .taper:
            return TodayPlan(activities: [
                PlannedActivity(name: "Shakeout Run", emoji: "🏃", durationMinutes: 25, targetCalories: 200, details: "Easy shakeout, focus on form and relaxation")
            ], calorieGoal: 200)
        }
    }

    private func buildProjections(from daily: [(date: Date, precipitationProbability: Double)]) -> [DailyProjection] {
        let baseSleep = sleepHours ?? 7.0

        return daily.enumerated().map { index, day in
            // Assume sleep normalizes to 7h after tonight unless new HealthKit data arrives.
            let projectedSleep = index == 0 ? baseSleep : max(baseSleep, 7.0)
            return DailyProjection(
                date: day.date,
                projectedSleepHours: projectedSleep,
                precipitationProbability: day.precipitationProbability
            )
        }
    }

    private func rebuildProjectionSleep() {
        guard !projections.isEmpty else { return }

        let rainfallByDay = projections.map { ($0.date, $0.precipitationProbability) }
        projections = buildProjections(from: rainfallByDay)
    }

    private func refreshOrchestratedPlan(with readiness: DailyReadiness? = nil) {
        let store = UserStore.shared
        let context = OrchestratorContext(
            mood: selectedMood,
            sleepHours: sleepHours,
            rainProbability: precipitationProbability,
            temperatureCelsius: temperatureCelsius,
            activityPreset: store.activityPreset,
            goalName: store.goalName.isEmpty ? "Training Goal" : store.goalName,
            goalPhase: store.currentGoalPhase,
            readiness: readiness,
            weatherImpact: (precipitationProbability ?? 0) > 0.6 ? .rain : .clear,
            healthConditions: store.healthConditions,
            workoutPreferences: store.workoutPreferences,
            calorieTarget: 400
        )
        orchestratedPlan = orchestrator.buildPlan(context: context)
    }
}
