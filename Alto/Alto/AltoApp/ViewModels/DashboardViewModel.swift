import Foundation
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

    private let healthKitService: HealthKitService
    private let locationService: LocationService
    private let weatherService: WeatherDataService
    private let voiceParser: VoiceWorkoutParsing
    private let macroVisionService: MacroVisionService
    private let speechService: SpeechTranscriptionService
    private let orchestrator: Orchestrating
    private let notificationService: NotificationService

    init(
        healthKitService: HealthKitService,
        locationService: LocationService,
        weatherService: WeatherDataService,
        voiceParser: VoiceWorkoutParsing,
        macroVisionService: MacroVisionService,
        speechService: SpeechTranscriptionService,
        orchestrator: Orchestrating,
        notificationService: NotificationService
    ) {
        self.healthKitService = healthKitService
        self.locationService = locationService
        self.weatherService = weatherService
        self.voiceParser = voiceParser
        self.macroVisionService = macroVisionService
        self.speechService = speechService
        self.orchestrator = orchestrator
        self.notificationService = notificationService
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

        isAnalyzingMeal = true
        defer { isAnalyzingMeal = false }

        do {
            pendingMacroEstimate = try await macroVisionService.analyzeMeal(imageData: jpegData)
        } catch MacroVisionError.missingAPIKey {
            errorMessage = "Missing OPENAI_API_KEY environment variable."
        } catch {
            errorMessage = "Macro analysis failed: \(error.localizedDescription)"
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

        let plannedBurn = 500.0
        let targetRPE = orchestratedPlan?.shouldPivot == true ? 4 : 6
        let achieved = activeEnergyBurnedToday ?? 0

        let evaluation = sentinel.evaluateEffortGap(
            activeEnergyBurned: achieved,
            plannedBurn: plannedBurn,
            targetRPE: targetRPE,
            reportedRPE: reportedRPE
        )

        effortGapMessage = evaluation.message
    }

    func stopDictationIfNeeded() {
        guard isDictating else { return }
        speechService.stopTranscription()
        isDictating = false
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
        let context = OrchestratorContext(
            mood: selectedMood,
            sleepHours: sleepHours,
            rainProbability: precipitationProbability,
            activityPreset: "Custom",
            goalName: "July Marathon - Sub 4:15",
            goalPhase: .build,
            readiness: readiness
        )
        orchestratedPlan = orchestrator.buildPlan(context: context)
    }
}
