import SwiftUI

struct NutritionView: View {
    @ObservedObject var viewModel: NutritionViewModel

    var body: some View {
        ZStack {
            AltoTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    calorieCard
                    macrosCard
                    mealsCard
                    waterCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $viewModel.showAddMeal) {
            AddMealView(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nutrition 🥗")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(AltoTheme.textPrimary)
                Text("Fuel your performance.")
                    .font(.system(size: 13))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
            Spacer()
        }
        .padding(18)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Calorie Ring Card

    private var calorieCard: some View {
        HStack(spacing: 20) {
            // Calorie ring
            ZStack {
                Circle()
                    .stroke(AltoTheme.border, lineWidth: 10)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: viewModel.calorieProgress)
                    .stroke(AltoTheme.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Text("\(Int(viewModel.totalCalories))")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(AltoTheme.textPrimary)
                    Text("kcal")
                        .font(.system(size: 10))
                        .foregroundStyle(AltoTheme.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                calorieStatRow(label: "Goal", value: "\(Int(viewModel.dailyCalorieGoal)) kcal", color: AltoTheme.textSecondary)
                calorieStatRow(label: "Remaining", value: "\(Int(viewModel.caloriesRemaining)) kcal", color: AltoTheme.green)
            }
            Spacer()
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func calorieStatRow(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AltoTheme.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Macros Card

    private var macrosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("MACROS")

            macroRow(
                name: "Protein",
                current: viewModel.totalProtein,
                goal: viewModel.proteinGoalGrams,
                unit: "g",
                color: Color(red: 0.37, green: 0.64, blue: 0.98),
                progress: viewModel.proteinProgress
            )
            macroRow(
                name: "Carbs",
                current: viewModel.totalCarbs,
                goal: viewModel.carbsGoalGrams,
                unit: "g",
                color: AltoTheme.green,
                progress: viewModel.carbsProgress
            )
            macroRow(
                name: "Fat",
                current: viewModel.totalFat,
                goal: viewModel.fatGoalGrams,
                unit: "g",
                color: AltoTheme.primary,
                progress: viewModel.fatProgress
            )
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func macroRow(name: String, current: Double, goal: Double, unit: String, color: Color, progress: Double) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AltoTheme.textPrimary)
                Spacer()
                Text("\(Int(current))\(unit) / \(Int(goal))\(unit)")
                    .font(.system(size: 12))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AltoTheme.border)
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 7)
                }
            }
            .frame(height: 7)
        }
    }

    // MARK: - Meals Card

    private var mealsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("MEALS LOGGED")

            ForEach(viewModel.meals) { meal in
                mealRow(meal: meal)
                if meal.id != viewModel.meals.last?.id {
                    Divider().background(AltoTheme.border)
                }
            }
            .onDelete { offsets in viewModel.removeMeal(at: offsets) }

            // Add Meal row
            Button {
                viewModel.showAddMeal = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AltoTheme.primary)
                        .font(.system(size: 16))
                    Text("Add Meal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AltoTheme.primary)
                    Spacer()
                }
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AltoTheme.primary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func mealRow(meal: Meal) -> some View {
        HStack(spacing: 12) {
            Text(meal.emoji)
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AltoTheme.textPrimary)
                Text(meal.items)
                    .font(.system(size: 12))
                    .foregroundStyle(AltoTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(Int(meal.calories)) kcal")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AltoTheme.textPrimary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Water Card

    private var waterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("WATER INTAKE")

            HStack {
                Text("💧")
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1fL / %.1fL", viewModel.waterIntakeLiters, viewModel.waterGoalLiters))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AltoTheme.textPrimary)
                    Text(String(format: "%.1fL remaining", viewModel.waterRemaining))
                        .font(.system(size: 12))
                        .foregroundStyle(AltoTheme.textSecondary)
                }
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AltoTheme.border)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.37, green: 0.64, blue: 0.98))
                        .frame(width: geo.size.width * viewModel.waterProgress, height: 10)
                        .animation(.spring(), value: viewModel.waterProgress)
                }
            }
            .frame(height: 10)

            HStack(spacing: 10) {
                waterButton(label: "+250ml") {
                    viewModel.logWater(liters: 0.25)
                }
                waterButton(label: "+500ml") {
                    viewModel.logWater(liters: 0.5)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func waterButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.37, green: 0.64, blue: 0.98))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.37, green: 0.64, blue: 0.98).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(AltoTheme.primary)
    }
}
