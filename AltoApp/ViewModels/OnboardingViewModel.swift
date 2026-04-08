import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case personal
        case healthShield
        case activityLevel
        case workoutPreferences
        case goalTimeline
        case cycleDetails
    }

    @Published var draft = UserProfileDraft()
    @Published var currentStep: Step = .personal
    @Published var showHeartDisclaimer: Bool = false
    @Published var isSaving: Bool = false
    @Published var saveError: String?
    @Published var isOnboardingComplete: Bool = false

    private let profileRepository: ProfileRepository

    init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }

    var isLastStep: Bool {
        if draft.gender == .female {
            return currentStep == .cycleDetails
        }
        return currentStep == .goalTimeline
    }

    var totalSteps: Int {
        draft.gender == .female ? 6 : 5
    }

    var canContinue: Bool {
        switch currentStep {
        case .personal:
            return draft.isNameValid && draft.isAgeValid
        case .healthShield:
            return true
        case .activityLevel:
            return draft.isActivityValid
        case .workoutPreferences:
            return true
        case .goalTimeline:
            return draft.isGoalValid
        case .cycleDetails:
            return draft.isCycleDataValid
        }
    }

    var shouldShowCycleStep: Bool {
        draft.gender == .female
    }

    var ageValidationMessage: String? {
        if draft.isAgeValid { return nil }
        return "Age must be 14 or above."
    }

    var cycleValidationMessage: String? {
        if draft.isCycleDataValid { return nil }
        if draft.cycleLengthDays < 20 || draft.cycleLengthDays > 40 {
            return "Cycle length should be between 20 and 40 days."
        }
        if draft.periodDays < 1 {
            return "Period days must be at least 1."
        }
        if draft.lastPeriodDate > Date() {
            return "Last period date cannot be in the future."
        }
        return "Please check cycle details."
    }

    func sanitizedCurrentStep() {
        if !shouldShowCycleStep && currentStep == .cycleDetails {
            currentStep = .goalTimeline
        }
    }

    func updateGender(_ gender: Gender) {
        draft.gender = gender
        sanitizedCurrentStep()
    }

    func toggleCondition(_ condition: HealthCondition) {
        if draft.selectedConditions.contains(condition) {
            draft.selectedConditions.remove(condition)
        } else {
            draft.selectedConditions.insert(condition)
            if condition == .heartCondition {
                showHeartDisclaimer = true
            }
        }
    }

    func moveForward() {
        guard canContinue else { return }

        switch currentStep {
        case .personal:
            currentStep = .healthShield
        case .healthShield:
            currentStep = .activityLevel
        case .activityLevel:
            currentStep = .workoutPreferences
        case .workoutPreferences:
            currentStep = .goalTimeline
        case .goalTimeline:
            if shouldShowCycleStep {
                currentStep = .cycleDetails
            }
        case .cycleDetails:
            break
        }
    }

    func moveBack() {
        switch currentStep {
        case .personal:
            break
        case .healthShield:
            currentStep = .personal
        case .activityLevel:
            currentStep = .healthShield
        case .workoutPreferences:
            currentStep = .activityLevel
        case .goalTimeline:
            currentStep = .workoutPreferences
        case .cycleDetails:
            currentStep = .goalTimeline
        }
    }

    func submitOnboarding() async {
        guard canContinue else { return }
        saveError = nil

        let includeCycle = draft.gender == .female
        let record = UserProfileRecord(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: draft.gender.rawValue,
            age: draft.age,
            heightCm: draft.heightInCentimeters,
            heightUnit: "inches",
            weightLb: draft.weightLb,
            healthConditions: draft.selectedConditions.map(\.rawValue).sorted(),
            otherConditionText: draft.otherConditionText.isEmpty ? nil : draft.otherConditionText,
            activityPreset: draft.activityPreset.rawValue,
            activityFrequencyUnit: draft.activityPreset == .custom ? draft.activityFrequencyUnit.rawValue : nil,
            activityFrequencyValue: draft.activityPreset == .custom ? draft.activityFrequencyValue : nil,
            preferredWorkouts: draft.preferredWorkouts.map(\.rawValue).sorted(),
            goalName: draft.goalName.trimmingCharacters(in: .whitespacesAndNewlines),
            goalTimelineValue: draft.goalTimelineValue,
            goalTimelineUnit: draft.goalTimelineUnit.rawValue,
            periodDays: includeCycle ? draft.periodDays : nil,
            cycleLengthDays: includeCycle ? draft.cycleLengthDays : nil,
            lastPeriodDate: includeCycle ? draft.lastPeriodDate : nil
        )

        isSaving = true
        defer { isSaving = false }

        do {
            try await profileRepository.saveProfile(record)
            isOnboardingComplete = true
            UserStore.shared.save(from: record)
        } catch ProfileRepositoryError.missingConfiguration {
            saveError = "Missing SUPABASE_URL or SUPABASE_ANON_KEY environment variables."
        } catch ProfileRepositoryError.requestFailed(let statusCode, let message) {
            saveError = "Supabase request failed (\(statusCode)): \(message)"
        } catch {
            saveError = error.localizedDescription
        }
    }
}
