import Foundation
import UIKit

@MainActor
final class NutritionViewModel: ObservableObject {
    @Published var meals: [Meal] = [
        Meal(name: "Breakfast", emoji: "🌅", items: "Oats, banana, almond milk",
             calories: 410, proteinGrams: 14, carbsGrams: 68, fatGrams: 9),
        Meal(name: "Lunch", emoji: "☀️", items: "Grilled chicken, brown rice, salad",
             calories: 620, proteinGrams: 52, carbsGrams: 58, fatGrams: 14),
        Meal(name: "Snack", emoji: "🍎", items: "Greek yogurt, berries",
             calories: 180, proteinGrams: 12, carbsGrams: 22, fatGrams: 5)
    ]
    @Published var waterIntakeLiters: Double = 1.8
    @Published var showAddMeal: Bool = false

    // Photo analysis state (used by AddMealView)
    @Published var capturedMealImage: UIImage?
    @Published var pendingMealEstimate: MacroEstimate?
    @Published var isAnalyzingMeal: Bool = false
    @Published var analysisError: String?

    let dailyCalorieGoal: Double = 2100
    let proteinGoalGrams: Double = 150
    let carbsGoalGrams: Double = 200
    let fatGoalGrams: Double = 65
    let waterGoalLiters: Double = 2.5

    private let macroVisionService: MacroVisionService = OpenAIVisionMacroService()

    // MARK: - Computed

    var totalCalories: Double { meals.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double  { meals.reduce(0) { $0 + $1.proteinGrams } }
    var totalCarbs: Double    { meals.reduce(0) { $0 + $1.carbsGrams } }
    var totalFat: Double      { meals.reduce(0) { $0 + $1.fatGrams } }

    var caloriesRemaining: Double { max(0, dailyCalorieGoal - totalCalories) }
    var calorieProgress: Double   { min(1, totalCalories / dailyCalorieGoal) }
    var proteinProgress: Double   { min(1, totalProtein / proteinGoalGrams) }
    var carbsProgress: Double     { min(1, totalCarbs / carbsGoalGrams) }
    var fatProgress: Double       { min(1, totalFat / fatGoalGrams) }
    var waterProgress: Double     { min(1, waterIntakeLiters / waterGoalLiters) }
    var waterRemaining: Double    { max(0, waterGoalLiters - waterIntakeLiters) }

    // MARK: - Meal actions

    func addMeal(_ meal: Meal) { meals.append(meal) }

    func removeMeal(at offsets: IndexSet) { meals.remove(atOffsets: offsets) }

    func logWater(liters: Double) {
        waterIntakeLiters = min(waterGoalLiters + 0.5, waterIntakeLiters + liters)
    }

    // MARK: - Photo analysis

    func analyzePhoto() async {
        guard let image = capturedMealImage,
              let jpegData = image.jpegData(compressionQuality: 0.8) else { return }

        analysisError = nil
        pendingMealEstimate = nil
        isAnalyzingMeal = true
        defer { isAnalyzingMeal = false }

        do {
            pendingMealEstimate = try await macroVisionService.analyzeMeal(imageData: jpegData)
        } catch MacroVisionError.missingAPIKey {
            analysisError = "Missing OPENAI_API_KEY. Add it to your environment variables."
        } catch {
            analysisError = "Could not analyze photo: \(error.localizedDescription)"
        }
    }
}
