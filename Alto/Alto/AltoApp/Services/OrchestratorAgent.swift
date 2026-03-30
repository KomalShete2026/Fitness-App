import Foundation

protocol Orchestrating {
    func buildPlan(context: OrchestratorContext) -> OrchestratedPlan
}

class SentinelOrchestrator: Orchestrating {
    // DWQ: 3 high-impact questions for a 10s check-in
    func dailyWellnessQuestionnaire() -> [DailySentinelQuestion] {
        [
            DailySentinelQuestion(
                title: "How do your muscles feel?",
                scaleMinLabel: "Like lead (1)",
                scaleMaxLabel: "Ready to spring (5)"
            ),
            DailySentinelQuestion(
                title: "How is your mental life load today?",
                scaleMinLabel: "Overwhelmed (1)",
                scaleMaxLabel: "Calm (5)"
            ),
            DailySentinelQuestion(
                title: "What is your motivation level?",
                scaleMinLabel: "I'd rather stay in bed (1)",
                scaleMaxLabel: "Let's go (5)"
            )
        ]
    }

    // Weighted scoring engine: soreness 40%, stress 30%, mood 30%
    // Codex instruction compatibility: if soreness < 3 deduct 30; if stress < 3 deduct 20.
    func readinessScore(from readiness: DailyReadiness) -> ReadinessScore {
        var score = 100
        var reasons: [String] = []

        if readiness.soreness < 3 {
            score -= 30
            reasons.append("high soreness")
        }

        if readiness.stress < 3 {
            score -= 20
            reasons.append("high life stress")
        }

        // Additional weighted mood effect.
        if readiness.mood < 3 {
            score -= 20
            reasons.append("low motivation")
        } else if readiness.mood == 3 {
            score -= 10
        }

        // Light phase penalty in luteal phase for max-intensity management.
        if readiness.cyclePhase == .luteal {
            score -= 10
            reasons.append("luteal phase")
        }

        return ReadinessScore(score: max(0, min(100, score)), reasons: reasons)
    }

    func pivotTaskIfNeeded(
        plannedTask: PlannedTask,
        readinessScore: Int,
        weatherImpact: WeatherImpact,
        cyclePhase: CyclePhase
    ) -> PlannedTask {
        var task = plannedTask

        // Required rule: if readiness < 40 -> Rest & Walk.
        if readinessScore < 40 {
            return PlannedTask(
                name: "Rest & Walk",
                durationMinutes: 25,
                location: .indoor,
                targetRPE: 2,
                plannedBurn: 120
            )
        }

        // Required rule: if rain + outdoor -> Indoor Circuit.
        if weatherImpact == .rain, task.location == .outdoor {
            task.name = "Indoor Circuit"
            task.location = .indoor
            task.targetRPE = min(task.targetRPE, 6)
        }

        // Metabolic pivot for luteal phase.
        if cyclePhase == .luteal {
            task.targetRPE = min(task.targetRPE, 7)
            task.durationMinutes = max(20, Int(Double(task.durationMinutes) * 0.9))
        }

        return task
    }

    // Onboarding honesty bot: capacity vs required volume increase.
    func auditOnboarding(_ input: OnboardingAuditInput) -> OnboardingAuditResult {
        let weeks = max(1, Calendar.current.dateComponents([.day], from: input.today, to: input.targetDate).day ?? 0) / 7
        let delta = input.requiredWeeklyVolumeAtDeadline - input.currentWeeklyVolume

        let requiredWeeklyIncrease = delta / Double(max(1, weeks))
        let base = max(1.0, input.currentWeeklyVolume)
        let increasePercent = (requiredWeeklyIncrease / base) * 100

        guard increasePercent > 15 else {
            return OnboardingAuditResult(
                isFeasible: true,
                requiredWeeklyIncreasePercent: increasePercent,
                injuryRiskPercent: nil,
                recommendedExtensionWeeks: nil,
                honestFeedback: nil
            )
        }

        // Heuristic extension to bring increase closer to 10-12%.
        let safeWeeklyIncrease = base * 0.12
        let neededWeeks = Int(ceil(max(0, delta) / max(1, safeWeeklyIncrease)))
        let extension = max(2, neededWeeks - weeks)

        let feedback = "I love the \(input.goalName) dream. Jumping from your current activity to this timeline requires a \(Int(increasePercent.rounded()))% weekly load increase, which is above the safe 15% threshold and raises injury risk. Let's extend your path by \(extension) weeks to include tendon loading and durability. Should I update the timeline?"

        return OnboardingAuditResult(
            isFeasible: false,
            requiredWeeklyIncreasePercent: increasePercent,
            injuryRiskPercent: 70,
            recommendedExtensionWeeks: extension,
            honestFeedback: feedback
        )
    }

    // Close-loop effort gap and post-workout RPE intelligence.
    func evaluateEffortGap(
        activeEnergyBurned: Double,
        plannedBurn: Double,
        targetRPE: Int,
        reportedRPE: Int
    ) -> EffortGapEvaluation {
        let safePlannedBurn = max(1, plannedBurn)
        let ratio = activeEnergyBurned / safePlannedBurn

        let triggerCompassionate = ratio < 0.5
        let triggerRecovery = targetRPE <= 4 && reportedRPE >= 9

        let message: String
        if triggerRecovery {
            message = "Perceived effort was very high vs planned easy session. Insert a mandatory deep recovery day for next 24h."
        } else if triggerCompassionate {
            message = "Less than 50% of planned burn reached. Trigger compassionate re-engagement notification."
        } else {
            message = "Effort gap within expected range. Continue planned progression."
        }

        return EffortGapEvaluation(
            achievedRatio: ratio,
            triggerCompassionateReengagement: triggerCompassionate,
            triggerRecoveryDay: triggerRecovery,
            message: message
        )
    }

    func buildPlan(context: OrchestratorContext) -> OrchestratedPlan {
        let readiness = context.readiness ?? DailyReadiness(
            soreness: mappedSoreness(from: context.mood),
            stress: mappedStress(from: context.mood),
            mood: mappedMotivation(from: context.mood),
            cyclePhase: .unknown
        )

        let score = readinessScore(from: readiness)

        let baseTask = plannedTask(for: context.goalPhase)
        let weather = context.weatherImpact == .clear
            ? ((context.rainProbability ?? 0) > 0.5 ? WeatherImpact.rain : .clear)
            : context.weatherImpact

        let finalTask = pivotTaskIfNeeded(
            plannedTask: baseTask,
            readinessScore: score.score,
            weatherImpact: weather,
            cyclePhase: readiness.cyclePhase
        )

        let shouldPivot = finalTask.name != baseTask.name
        let why = score.reasons.isEmpty ? "Readiness looks stable." : "Signals: \(score.reasons.joined(separator: ", "))."

        return OrchestratedPlan(
            headline: shouldPivot ? "Adaptive Pivot Applied" : "On-Track Session",
            why: "Readiness \(score.score)/100. \(why)",
            workoutName: finalTask.name,
            workoutDurationMinutes: finalTask.durationMinutes,
            actions: [
                OrchestratedAction(title: "Coach Decision", details: shouldPivot ? "Plan adjusted for safety and consistency." : "Proceed with planned workload."),
                OrchestratedAction(title: "Target Intensity", details: "RPE \(finalTask.targetRPE)/10"),
                OrchestratedAction(title: "Environment", details: finalTask.location == .indoor ? "Indoor" : "Outdoor")
            ],
            shouldPivot: shouldPivot
        )
    }

    private func plannedTask(for phase: GoalPhase) -> PlannedTask {
        switch phase {
        case .base:
            return PlannedTask(name: "Base Aerobic Run", durationMinutes: 40, location: .outdoor, targetRPE: 5, plannedBurn: 420)
        case .build:
            return PlannedTask(name: "Tempo Intervals", durationMinutes: 45, location: .outdoor, targetRPE: 7, plannedBurn: 520)
        case .peak:
            return PlannedTask(name: "Race Pace Session", durationMinutes: 50, location: .outdoor, targetRPE: 8, plannedBurn: 600)
        case .taper:
            return PlannedTask(name: "Taper Shakeout", durationMinutes: 25, location: .outdoor, targetRPE: 4, plannedBurn: 220)
        }
    }

    private func mappedSoreness(from mood: DailyMood) -> Int {
        switch mood {
        case .readyToPush: return 5
        case .balanced: return 4
        case .lowEnergy: return 3
        case .muscleFatigue: return 2
        case .mentallyDrained: return 3
        case .needRecovery: return 1
        }
    }

    private func mappedStress(from mood: DailyMood) -> Int {
        switch mood {
        case .readyToPush: return 5
        case .balanced: return 4
        case .lowEnergy: return 3
        case .muscleFatigue: return 3
        case .mentallyDrained: return 2
        case .needRecovery: return 2
        }
    }

    private func mappedMotivation(from mood: DailyMood) -> Int {
        switch mood {
        case .readyToPush: return 5
        case .balanced: return 4
        case .lowEnergy: return 2
        case .muscleFatigue: return 2
        case .mentallyDrained: return 1
        case .needRecovery: return 1
        }
    }
}

// Backward compatibility alias for existing callsites.
typealias RuleBasedOrchestratorAgent = SentinelOrchestrator
