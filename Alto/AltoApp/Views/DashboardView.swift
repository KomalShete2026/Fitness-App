import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel(
        healthKitService: AppleHealthKitService(),
        locationService: CoreLocationService(),
        weatherService: AppleWeatherService(),
        voiceParser: VoiceWorkoutParser(),
        macroVisionService: OpenAIVisionMacroService(),
        speechService: AppleSpeechTranscriptionService(),
        orchestrator: SentinelOrchestrator(),
        notificationService: UserNotificationService()
    )
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today")
                    .font(.largeTitle.weight(.bold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio-Sync")
                        .font(.headline)
                    Text("Last Night's Sleep: \(viewModel.sleepDisplayText)")
                        .font(.title3.weight(.semibold))
                    Text("Status: \(viewModel.healthStatusText)")
                        .foregroundStyle(.secondary)
                    Button("Connect HealthKit") {
                        Task { await viewModel.connectHealthKit() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Environment Scout")
                        .font(.headline)
                    Text("Temperature: \(viewModel.weatherDisplayText)")
                    Text("Precipitation: \(viewModel.precipitationDisplayText)")
                    if viewModel.weatherConflict {
                        Text("Weather Conflict: Rain probability > 50%")
                            .foregroundStyle(.orange)
                            .fontWeight(.semibold)
                    } else {
                        Text("Weather Conflict: None")
                            .foregroundStyle(.secondary)
                    }
                    Text("Status: \(viewModel.weatherStatusText)")
                        .foregroundStyle(.secondary)
                    Button("Refresh Weather") {
                        Task { await viewModel.refreshWeather() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Orchestrator Agent")
                        .font(.headline)

                    Button("Schedule Daily Sentinel (7:00 AM)") {
                        Task { await viewModel.scheduleDailySentinelNotification() }
                    }
                    .buttonStyle(.borderedProminent)

                    Text("How are you today?")
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(DailyMood.allCases) { mood in
                                Button(mood.rawValue) {
                                    viewModel.setMood(mood)
                                }
                                .buttonStyle(.bordered)
                                .tint(viewModel.selectedMood == mood ? AltoTheme.primary : .gray)
                            }
                        }
                    }

                    if let plan = viewModel.orchestratedPlan {
                        Text(plan.headline)
                            .font(.title3.weight(.bold))
                        Text(plan.why)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Workout: \(plan.workoutName) • \(plan.workoutDurationMinutes) min")
                            .font(.subheadline.weight(.semibold))

                        ForEach(plan.actions) { action in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(action.title)
                                    .font(.subheadline.weight(.bold))
                                Text(action.details)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Sentinel Check-In")
                        .font(.headline)

                    Stepper("Soreness: \(viewModel.sorenessScore)", value: $viewModel.sorenessScore, in: 1...5)
                    Stepper("Stress: \(viewModel.stressScore)", value: $viewModel.stressScore, in: 1...5)
                    Stepper("Motivation: \(viewModel.motivationScore)", value: $viewModel.motivationScore, in: 1...5)

                    Picker("Cycle Phase", selection: $viewModel.selectedCyclePhase) {
                        ForEach(CyclePhase.allCases, id: \.self) { phase in
                            Text(phase.rawValue).tag(phase)
                        }
                    }
                    .pickerStyle(.menu)

                    Button("Submit DWQ") {
                        viewModel.submitDailyWellness()
                    }
                    .buttonStyle(.borderedProminent)

                    if let score = viewModel.readinessScore {
                        Text("Readiness Score: \(score)/100")
                            .font(.subheadline.weight(.bold))
                        if !viewModel.readinessReasons.isEmpty {
                            Text("Signals: \(viewModel.readinessReasons.joined(separator: ", "))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Morning Pivot")
                        .font(.headline)

                    if viewModel.pivotDecision.shouldPivot {
                        Text("Pivoted")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.orange, in: Capsule())

                        Text("Why: \(viewModel.pivotDecision.whyText)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text("Hard Workout: \(viewModel.plannedWorkout.name)")
                        Text("Current Date: \(viewModel.plannedWorkout.scheduledDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.footnote)

                        Button("Accept") {
                            viewModel.acceptPivot()
                        }
                        .buttonStyle(.borderedProminent)

                        if viewModel.pivotAccepted {
                            Text("Rescheduled to: \(viewModel.plannedWorkout.scheduledDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.footnote)
                                .foregroundStyle(.green)
                        }
                    } else {
                        Text("No pivot needed today.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Post-Workout Feedback Loop")
                        .font(.headline)

                    Text("Active Energy Burned Today: \(Int((viewModel.activeEnergyBurnedToday ?? 0).rounded())) kcal")
                        .foregroundStyle(.secondary)

                    Stepper("Reported RPE: \(viewModel.reportedRPE)", value: $viewModel.reportedRPE, in: 1...10)

                    Button("Evaluate Effort Gap") {
                        viewModel.evaluatePostWorkout()
                    }
                    .buttonStyle(.borderedProminent)

                    if let message = viewModel.effortGapMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Input Hub: Invisible Log")
                        .font(.headline)
                    TextField("I did 30 mins of Yoga", text: $viewModel.voiceTranscript)
                        .textInputAutocapitalization(.sentences)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                    Button(viewModel.isDictating ? "Stop Dictation" : "Start Dictation") {
                        Task { await viewModel.toggleDictation() }
                    }
                    .buttonStyle(.bordered)

                    Button("Parse Voice Log") {
                        viewModel.parseVoiceLog()
                    }
                    .buttonStyle(.borderedProminent)

                    if let log = viewModel.lastVoiceLog {
                        Text("Logged: \(log.durationMinutes) mins of \(log.workoutType)")
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }

                    Text("Path Progress: \(viewModel.pathProgressSessions) sessions")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Input Hub: Macro-Vision")
                        .font(.headline)

                    Button("Capture Meal Photo") {
                        showCamera = true
                    }
                    .buttonStyle(.borderedProminent)

                    if let image = viewModel.selectedMealImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button(viewModel.isAnalyzingMeal ? "Analyzing..." : "Analyze Macros") {
                            Task { await viewModel.analyzeSelectedMealImage() }
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isAnalyzingMeal)
                    }

                    if let estimate = viewModel.pendingMacroEstimate {
                        Text("Detected: \(estimate.calories) kcal | P \(Int(estimate.proteinGrams))g | C \(Int(estimate.carbsGrams))g | F \(Int(estimate.fatGrams))g")
                            .font(.footnote)
                        Button("Confirm Macros") {
                            viewModel.confirmMacros()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Text("Daily Total: \(viewModel.macroTotalsText)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .task {
            await viewModel.loadDashboard()
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $viewModel.selectedMealImage)
        }
        .onDisappear {
            viewModel.stopDictationIfNeeded()
        }
    }
}
