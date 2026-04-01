import XCTest
@testable import Alto

// MARK: - NutritionViewModel Tests

final class NutritionViewModelTests: XCTestCase {

    var viewModel: NutritionViewModel!

    override func setUp() {
        super.setUp()
        viewModel = NutritionViewModel()
    }

    func test_initialMeals_notEmpty() {
        XCTAssertFalse(viewModel.meals.isEmpty)
    }

    func test_addMeal_increasesMealCount() {
        let initial = viewModel.meals.count
        let meal = Meal(
            name: "Test Meal",
            emoji: "🍎",
            items: "Apple",
            calories: 80,
            proteinGrams: 0,
            carbsGrams: 21,
            fatGrams: 0
        )
        viewModel.addMeal(meal)
        XCTAssertEqual(viewModel.meals.count, initial + 1)
    }

    func test_removeMeal_decreasesMealCount() {
        let initial = viewModel.meals.count
        viewModel.removeMeal(at: IndexSet(integer: 0))
        XCTAssertEqual(viewModel.meals.count, initial - 1)
    }

    func test_totalCalories_calculatesCorrectly() {
        viewModel.meals = [
            Meal(name: "A", emoji: "🍎", items: "", calories: 300, proteinGrams: 10, carbsGrams: 40, fatGrams: 5),
            Meal(name: "B", emoji: "🍌", items: "", calories: 200, proteinGrams: 5,  carbsGrams: 45, fatGrams: 2),
        ]
        XCTAssertEqual(viewModel.totalCalories, 500)
    }

    func test_totalCalories_emptyMeals_returnsZero() {
        viewModel.meals = []
        XCTAssertEqual(viewModel.totalCalories, 0)
    }

    func test_remainingCalories_calculatesCorrectly() {
        viewModel.meals = [
            Meal(name: "A", emoji: "🍎", items: "", calories: 800, proteinGrams: 30, carbsGrams: 80, fatGrams: 20),
        ]
        // Goal is 2100
        XCTAssertEqual(viewModel.caloriesRemaining, 1300)
    }

    func test_waterProgress_withinBounds() {
        viewModel.waterIntakeLiters = 1.0
        XCTAssertGreaterThanOrEqual(viewModel.waterProgress, 0)
        XCTAssertLessThanOrEqual(viewModel.waterProgress, 1)
    }

    func test_waterProgress_fullGoal_returnsOne() {
        viewModel.waterIntakeLiters = viewModel.waterGoalLiters
        XCTAssertEqual(viewModel.waterProgress, 1.0, accuracy: 0.001)
    }

    func test_addWater_incrementsIntake() {
        let initial = viewModel.waterIntakeLiters
        viewModel.logWater(liters: 0.25)
        XCTAssertEqual(viewModel.waterIntakeLiters, initial + 0.25, accuracy: 0.001)
    }

    func test_macroGoals_nonZero() {
        XCTAssertGreaterThan(viewModel.proteinGoalGrams, 0)
        XCTAssertGreaterThan(viewModel.carbsGoalGrams, 0)
        XCTAssertGreaterThan(viewModel.fatGoalGrams, 0)
    }
}
