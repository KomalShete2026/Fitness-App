import SwiftUI

struct AddMealView: View {
    @ObservedObject var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var mealName: String = ""
    @State private var mealItems: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var selectedEmoji: String = "🍽️"
    @State private var showCamera: Bool = false

    private let emojiOptions = ["🍽️","🌅","☀️","🌙","🍎","🥗","🍳","🥩","🍚","🥦","🍌","🧃","🥤","🍫","🥜"]

    var canSave: Bool {
        !mealName.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(calories) != nil
    }

    var body: some View {
        ZStack {
            AltoTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button("Cancel") { dismiss() }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AltoTheme.textSecondary)
                        Spacer()
                        Text("Log a Meal")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AltoTheme.textPrimary)
                        Spacer()
                        Button("Save") { saveMeal() }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(canSave ? AltoTheme.primary : AltoTheme.textSecondary)
                            .disabled(!canSave)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Photo capture
                    photoSection

                    // Emoji picker
                    emojiSection

                    // Name & description
                    detailsSection

                    // Macros
                    macrosSection
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $viewModel.capturedMealImage)
        }
        .onChange(of: viewModel.capturedMealImage) { _, image in
            if image != nil {
                Task { await viewModel.analyzePhoto() }
            }
        }
        .onChange(of: viewModel.pendingMealEstimate) { _, estimate in
            if let e = estimate {
                calories = "\(e.calories)"
                protein  = String(format: "%.0f", e.proteinGrams)
                carbs    = String(format: "%.0f", e.carbsGrams)
                fat      = String(format: "%.0f", e.fatGrams)
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(spacing: 10) {
            if let image = viewModel.capturedMealImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
                    .padding(.horizontal, 16)

                if viewModel.isAnalyzingMeal {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(AltoTheme.primary)
                        Text("Analyzing macros…")
                            .font(.system(size: 13))
                            .foregroundStyle(AltoTheme.textSecondary)
                    }
                } else if viewModel.pendingMealEstimate != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(AltoTheme.primary)
                        Text("Macros auto-filled from photo")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AltoTheme.primary)
                    }
                }

                Button {
                    viewModel.capturedMealImage = nil
                    viewModel.pendingMealEstimate = nil
                } label: {
                    Text("Remove photo")
                        .font(.system(size: 12))
                        .foregroundStyle(AltoTheme.textSecondary)
                }
            } else {
                Button { showCamera = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Snap your meal")
                                .font(.system(size: 14, weight: .semibold))
                            Text("AI will estimate calories & macros")
                                .font(.system(size: 12))
                                .foregroundStyle(AltoTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(AltoTheme.textSecondary)
                    }
                    .foregroundStyle(AltoTheme.textPrimary)
                    .padding(16)
                    .background(AltoTheme.card)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AltoTheme.primary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6])))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Emoji Section

    private var emojiSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ICON")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(emojiOptions, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.system(size: 22))
                                .frame(width: 44, height: 44)
                                .background(selectedEmoji == emoji ? AltoTheme.primary.opacity(0.18) : AltoTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedEmoji == emoji ? AltoTheme.primary : AltoTheme.border, lineWidth: 1.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("DETAILS")

            VStack(spacing: 1) {
                inputField(label: "Meal name", placeholder: "e.g. Lunch, Post-workout snack", text: $mealName)
                Divider().background(AltoTheme.border)
                inputField(label: "What's in it?", placeholder: "e.g. Grilled chicken, rice, veggies", text: $mealItems)
            }
            .background(AltoTheme.card)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AltoTheme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Macros Section

    private var macrosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("MACROS")
                if viewModel.pendingMealEstimate != nil {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("AI estimated")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(AltoTheme.primary)
                }
            }

            VStack(spacing: 1) {
                macroField(label: "Calories", unit: "kcal", value: $calories, color: AltoTheme.primary)
                Divider().background(AltoTheme.border)
                macroField(label: "Protein", unit: "g", value: $protein, color: Color(red: 0.37, green: 0.64, blue: 0.98))
                Divider().background(AltoTheme.border)
                macroField(label: "Carbohydrates", unit: "g", value: $carbs, color: AltoTheme.green)
                Divider().background(AltoTheme.border)
                macroField(label: "Fat", unit: "g", value: $fat, color: AltoTheme.primary)
            }
            .background(AltoTheme.card)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AltoTheme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers

    private func inputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AltoTheme.textSecondary)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundStyle(AltoTheme.textPrimary)
                .tint(AltoTheme.primary)
        }
        .padding(14)
    }

    private func macroField(label: String, unit: String, value: Binding<String>, color: Color) -> some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AltoTheme.textPrimary)
            }
            Spacer()
            HStack(spacing: 4) {
                TextField("0", text: value)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AltoTheme.textPrimary)
                    .tint(AltoTheme.primary)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text(unit)
                    .font(.system(size: 13))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(2)
            .foregroundStyle(AltoTheme.primary)
    }

    private func saveMeal() {
        let meal = Meal(
            name: mealName.trimmingCharacters(in: .whitespaces),
            emoji: selectedEmoji,
            items: mealItems.trimmingCharacters(in: .whitespaces),
            calories: Double(calories) ?? 0,
            proteinGrams: Double(protein) ?? 0,
            carbsGrams: Double(carbs) ?? 0,
            fatGrams: Double(fat) ?? 0
        )
        viewModel.addMeal(meal)
        viewModel.capturedMealImage = nil
        viewModel.pendingMealEstimate = nil
        dismiss()
    }
}
