import XCTest
@testable import Alto

// MARK: - SentinelOrchestrator Tests
// Tests the readiness scoring engine and pivot logic

final class SentinelOrchestratorTests: XCTestCase {

    var orchestrator: SentinelOrchestrator!

    override func setUp() {
        super.setUp()
        orchestrator = SentinelOrchestrator()
    }

    // MARK: - Readiness Score Tests

    func test_readinessScore_perfectSignals_returns100() {
        let readiness = DailyReadiness(soreness: 5, stress: 5, mood: 5, cyclePhase: .follicular)
        let result = orchestrator.readinessScore(from: readiness)
        XCTAssertEqual(result.score, 100)
        XCTAssertTrue(result.reasons.isEmpty)
    }

    func test_readinessScore_highSoreness_deducts30() {
        let readiness = DailyReadiness(soreness: 2, stress: 5, mood: 5, cyclePhase: .follicular)
        let result = orchestrator.readinessScore(from: readiness)
        XCTAssertEqual(result.score, 70)
        XCTAssertTrue(result.reasons.contains("high soreness"))
    }

    func test_readinessScore_highStress_deducts20() {
        let readiness = DailyReadiness(soreness: 5, stress: 2, mood: 5, cyclePhase: .follicular)
        let result = orchestrator.readinessScore(from: readiness)
        XCTAssertEqual(result.score, 80)
        XCTAssertTrue(result.reasons.contains("high life stress"))
    }

    func test_readinessScore_lowMotivation_deducts20() {
        let readiness = DailyReadiness(soreness: 5, stress: 5, mood: 2, cyclePhase: .follicular)
        let result = orchestrator.readinessScore(from: readiness)
        XCTAssertEqual(result.score, 80)
        XCTAssertTrue(result.reasons.contains("low motivation"))
    }

    func test_readinessScore_neutralMotivation_deducts10() {
        let readiness = DailyReadiness(soreness: 5, stress: 5, mood: 3, cyclePhase: .follicular)
        let result = orchestrator.readinessScore(from: readiness)
        XCTAssertEqual(result.score, 90)
    }

    func test_readinessScore_lutealPhase_deducts10() {
        let readiness = DailyReadiness(soreness: 5, stress: 5, mood: 5, cyclePhase: .luteal)
        let result = orchestrator.readinessScore(from: readiness)
        XCTAssertEqual(result.score, 90)
        XCTAssertTrue(result.reasons.contains("luteal phase"))
    }

    func test_readinessScore_worstSignals_doesNotGoBelowZero() {
        let readiness = DailyReadiness(soreness: 1, stress: 1, mood: 1, cyclePhase: .luteal)
        let result = orchestrator.readinessScore(from: readiness)
        XCTAssertGreaterThanOrEqual(result.score, 0)
        XCTAssertLessThanOrEqual(result.score, 100)
    }

    func test_readinessScore_allPenalties_combinedCorrectly() {
        // soreness<3: -30, stress<3: -20, mood<3: -20, luteal: -10 = 20
        let readiness = DailyReadiness(soreness: 2, stress: 2, mood: 2, cyclePhase: .luteal)
        let result = orchestrator.readinessScore(from: readiness)
        XCTAssertEqual(result.score, 20)
    }

    // MARK: - Pivot Logic Tests

    func test_pivot_lowReadiness_returnsRestAndWalk() {
        let task = PlannedTask(name: "Tempo Run", durationMinutes: 45, location: .outdoor, targetRPE: 7, plannedBurn: 500)
        let result = orchestrator.pivotTaskIfNeeded(
            plannedTask: task,
            readinessScore: 35,
            weatherImpact: .clear,
            cyclePhase: .follicular
        )
        XCTAssertEqual(result.name, "Rest & Walk")
        XCTAssertEqual(result.durationMinutes, 25)
        XCTAssertEqual(result.targetRPE, 2)
    }

    func test_pivot_readinessAt40_doesNotForceRest() {
        let task = PlannedTask(name: "Easy Run", durationMinutes: 30, location: .outdoor, targetRPE: 5, plannedBurn: 300)
        let result = orchestrator.pivotTaskIfNeeded(
            plannedTask: task,
            readinessScore: 40,
            weatherImpact: .clear,
            cyclePhase: .follicular
        )
        XCTAssertNotEqual(result.name, "Rest & Walk")
    }

    func test_pivot_rainAndOutdoor_swapsToIndoorCircuit() {
        let task = PlannedTask(name: "Outdoor Run", durationMinutes: 45, location: .outdoor, targetRPE: 7, plannedBurn: 450)
        let result = orchestrator.pivotTaskIfNeeded(
            plannedTask: task,
            readinessScore: 80,
            weatherImpact: .rain,
            cyclePhase: .follicular
        )
        XCTAssertEqual(result.name, "Indoor Circuit")
        XCTAssertEqual(result.location, .indoor)
        XCTAssertLessThanOrEqual(result.targetRPE, 6)
    }

    func test_pivot_rainAndIndoor_noChange() {
        let task = PlannedTask(name: "Yoga", durationMinutes: 45, location: .indoor, targetRPE: 4, plannedBurn: 200)
        let result = orchestrator.pivotTaskIfNeeded(
            plannedTask: task,
            readinessScore: 80,
            weatherImpact: .rain,
            cyclePhase: .follicular
        )
        XCTAssertEqual(result.name, "Yoga")
        XCTAssertEqual(result.location, .indoor)
    }

    func test_pivot_lutealPhase_capsRPEAt7() {
        let task = PlannedTask(name: "HIIT", durationMinutes: 40, location: .indoor, targetRPE: 9, plannedBurn: 450)
        let result = orchestrator.pivotTaskIfNeeded(
            plannedTask: task,
            readinessScore: 80,
            weatherImpact: .clear,
            cyclePhase: .luteal
        )
        XCTAssertLessThanOrEqual(result.targetRPE, 7)
    }

    func test_pivot_lutealPhase_reducesDurationBy10Percent() {
        let task = PlannedTask(name: "Run", durationMinutes: 40, location: .outdoor, targetRPE: 6, plannedBurn: 400)
        let result = orchestrator.pivotTaskIfNeeded(
            plannedTask: task,
            readinessScore: 80,
            weatherImpact: .clear,
            cyclePhase: .luteal
        )
        XCTAssertLessThan(result.durationMinutes, 40)
        XCTAssertGreaterThanOrEqual(result.durationMinutes, 20) // never below minimum
    }

    // MARK: - Build Plan Tests

    func test_buildPlan_highReadiness_returnsOnTrack() {
        let context = OrchestratorContext(
            mood: .readyToPush,
            sleepHours: 8.0,
            rainProbability: 0.1,
            activityPreset: "4x per week",
            goalName: "Marathon",
            goalPhase: .build,
            readiness: DailyReadiness(soreness: 5, stress: 5, mood: 5, cyclePhase: .follicular),
            weatherImpact: .clear
        )
        let plan = orchestrator.buildPlan(context: context)
        XCTAssertFalse(plan.shouldPivot)
        XCTAssertFalse(plan.workoutName.isEmpty)
        XCTAssertFalse(plan.headline.isEmpty)
    }

    func test_buildPlan_heavyRain_triggersPivot() {
        let context = OrchestratorContext(
            mood: .balanced,
            sleepHours: 7.0,
            rainProbability: 0.9,
            activityPreset: "4x per week",
            goalName: "Marathon",
            goalPhase: .build,
            readiness: DailyReadiness(soreness: 4, stress: 4, mood: 4, cyclePhase: .follicular),
            weatherImpact: .rain
        )
        let plan = orchestrator.buildPlan(context: context)
        XCTAssertTrue(plan.shouldPivot)
    }

    func test_buildPlan_eachPhaseProducesDistinctWorkout() {
        let phases: [GoalPhase] = [.base, .build, .peak, .taper]
        let readiness = DailyReadiness(soreness: 5, stress: 5, mood: 5, cyclePhase: .follicular)
        var workoutNames = Set<String>()

        for phase in phases {
            let context = OrchestratorContext(
                mood: .balanced,
                sleepHours: 7.5,
                rainProbability: 0.0,
                activityPreset: "4x per week",
                goalName: "Marathon",
                goalPhase: phase,
                readiness: readiness,
                weatherImpact: .clear
            )
            let plan = orchestrator.buildPlan(context: context)
            workoutNames.insert(plan.workoutName)
        }
        // Each phase should produce a different workout name
        XCTAssertEqual(workoutNames.count, 4)
    }

    // MARK: - Onboarding Audit Tests

    func test_auditOnboarding_feasibleTimeline_returnsNoWarning() {
        let input = OnboardingAuditInput(
            goalName: "5K",
            targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!,
            today: Date(),
            currentWeeklyVolume: 20,
            requiredWeeklyVolumeAtDeadline: 25
        )
        let result = orchestrator.auditOnboarding(input)
        XCTAssertTrue(result.isFeasible)
        XCTAssertNil(result.honestFeedback)
    }

    func test_auditOnboarding_aggressiveTimeline_returnsWarning() {
        let input = OnboardingAuditInput(
            goalName: "Marathon",
            targetDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            today: Date(),
            currentWeeklyVolume: 10,
            requiredWeeklyVolumeAtDeadline: 50
        )
        let result = orchestrator.auditOnboarding(input)
        XCTAssertFalse(result.isFeasible)
        XCTAssertNotNil(result.honestFeedback)
        XCTAssertNotNil(result.recommendedExtensionWeeks)
    }

    // MARK: - Effort Gap Tests

    func test_effortGap_achievedOver50Percent_noReengagement() {
        let result = orchestrator.evaluateEffortGap(
            activeEnergyBurned: 300,
            plannedBurn: 500,
            targetRPE: 6,
            reportedRPE: 7
        )
        XCTAssertFalse(result.triggerCompassionateReengagement)
        XCTAssertFalse(result.triggerRecoveryDay)
    }

    func test_effortGap_achievedUnder50Percent_triggersReengagement() {
        let result = orchestrator.evaluateEffortGap(
            activeEnergyBurned: 100,
            plannedBurn: 500,
            targetRPE: 6,
            reportedRPE: 6
        )
        XCTAssertTrue(result.triggerCompassionateReengagement)
    }

    func test_effortGap_easySessionPerceivedHard_triggersRecovery() {
        let result = orchestrator.evaluateEffortGap(
            activeEnergyBurned: 200,
            plannedBurn: 220,
            targetRPE: 3,
            reportedRPE: 9
        )
        XCTAssertTrue(result.triggerRecoveryDay)
    }

    func test_effortGap_ratioCalculation_correct() {
        let result = orchestrator.evaluateEffortGap(
            activeEnergyBurned: 250,
            plannedBurn: 500,
            targetRPE: 6,
            reportedRPE: 6
        )
        XCTAssertEqual(result.achievedRatio, 0.5, accuracy: 0.001)
    }
}
