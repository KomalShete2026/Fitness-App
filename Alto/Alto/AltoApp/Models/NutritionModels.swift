import Foundation

struct Meal: Identifiable {
    var id: UUID
    let name: String
    let emoji: String
    let items: String
    let calories: Double
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    let loggedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        items: String,
        calories: Double,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double,
        loggedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.items = items
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.loggedAt = loggedAt
    }
}
