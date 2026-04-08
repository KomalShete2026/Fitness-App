import Foundation

struct VoiceWorkoutEntry: Identifiable {
    let id = UUID()
    let workoutType: String
    let durationMinutes: Int
    let sourceText: String
    let loggedAt: Date
}

struct MacroEstimate: Codable {
    let calories: Int
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
}

struct DailyMacroTotal {
    var calories: Int = 0
    var proteinGrams: Double = 0
    var carbsGrams: Double = 0
    var fatGrams: Double = 0

    mutating func add(_ estimate: MacroEstimate) {
        calories += estimate.calories
        proteinGrams += estimate.proteinGrams
        carbsGrams += estimate.carbsGrams
        fatGrams += estimate.fatGrams
    }
}
