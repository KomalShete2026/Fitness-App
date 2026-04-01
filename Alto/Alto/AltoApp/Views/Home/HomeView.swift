import SwiftUI

struct HomeView: View {
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
    @EnvironmentObject private var userStore: UserStore

    var body: some View {
        ZStack {
            AltoTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    goalsSummaryCard
                    statusPillsRow
                    readinessCard
                    todayProgressCard
                    voiceLogCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }

            if viewModel.showSentinelPopup {
                SentinelPopupView(viewModel: viewModel)
                    .environmentObject(userStore)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .task { await viewModel.onAppear() }
        .animation(.spring(), value: viewModel.showSentinelPopup)
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Alto")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AltoTheme.primary)
                Text("Hi \(userStore.userName) 👋")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(AltoTheme.textPrimary)
                Text("Let's make today count.")
                    .font(.system(size: 13))
                    .foregroundStyle(AltoTheme.textSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(AltoTheme.primary, lineWidth: 2)
                    .frame(width: 52, height: 52)
                Text("🧑")
                    .font(.system(size: 26))
            }
        }
        .padding(18)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Goals Summary Card

    private var goalsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("YOUR GOALS")

            HStack(spacing: 12) {
                Text("🏅")
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text(userStore.goalName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AltoTheme.textPrimary)
                    Text("\(userStore.daysUntilGoal) days away · \(formattedTargetDate)")
                        .font(.system(size: 12))
                        .foregroundStyle(AltoTheme.textSecondary)
                }
                Spacer()
                goalBadge(daysUntilGoal: userStore.daysUntilGoal)
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func goalBadge(daysUntilGoal: Int) -> some View {
        if daysUntilGoal < 30 {
            Text("Soon")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AltoTheme.red)
                .clipShape(Capsule())
        } else {
            Text("On Track")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AltoTheme.primary)
                .clipShape(Capsule())
        }
    }

    private var formattedTargetDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: userStore.goalTargetDate)
    }

    // MARK: - Status Pills Row

    private var statusPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if viewModel.healthStatusText == "Connected" {
                    statusPill(color: AltoTheme.green, text: "HealthKit Connected")
                }
                statusPill(color: AltoTheme.primary, text: "\(userStore.currentGoalPhase.rawValue) Phase")
                statusPill(color: Color(red: 0.37, green: 0.64, blue: 0.98), text: viewModel.weatherStatusText)
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func statusPill(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AltoTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Readiness Card

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("DAILY READINESS")

            HStack(spacing: 16) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(AltoTheme.border, lineWidth: 8)
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: scoreFraction)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: viewModel.readinessScore)
                    Text(viewModel.readinessScore.map { "\($0)" } ?? "—")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(AltoTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(readinessTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AltoTheme.textPrimary)
                    Text(readinessDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(AltoTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !viewModel.readinessReasons.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(viewModel.readinessReasons, id: \.self) { reason in
                                    Text(reason)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(AltoTheme.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AltoTheme.surface)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var scoreFraction: Double {
        guard let score = viewModel.readinessScore else { return 0 }
        return Double(score) / 100.0
    }

    private var ringColor: Color {
        guard let score = viewModel.readinessScore else { return AltoTheme.border }
        if score >= 70 { return AltoTheme.green }
        if score >= 40 { return AltoTheme.primary }
        return AltoTheme.red
    }

    private var readinessTitle: String {
        guard let score = viewModel.readinessScore else { return "Check-in Needed" }
        if score >= 70 { return "Ready to Go" }
        if score >= 40 { return "Moderate Readiness" }
        return "Rest Recommended"
    }

    private var readinessDescription: String {
        guard let score = viewModel.readinessScore else { return "Complete your check-in" }
        if score >= 70 { return "Your body is primed for a quality session." }
        if score >= 40 { return "Consider moderate intensity today." }
        return "Prioritize recovery and light movement."
    }

    // MARK: - Today's Progress Card

    private var todayProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("TODAY'S PROGRESS")

            HStack {
                Text(viewModel.todayPlan.summaryText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AltoTheme.textPrimary)
                Text("·")
                    .foregroundStyle(AltoTheme.textSecondary)
                Text(userStore.goalName)
                    .font(.system(size: 13))
                    .foregroundStyle(AltoTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            // Overall progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AltoTheme.border)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AltoTheme.primary)
                        .frame(width: geo.size.width * viewModel.todayPlan.progressFraction, height: 8)
                        .animation(.spring(), value: viewModel.todayPlan.progressFraction)
                }
            }
            .frame(height: 8)

            // Activity rows
            VStack(spacing: 8) {
                ForEach(viewModel.todayPlan.activities) { activity in
                    activityRow(activity: activity)
                }
            }

            // Bottom stats
            HStack {
                Text("🔥 \(Int(viewModel.todayPlan.totalCaloriesBurned)) / \(Int(viewModel.todayPlan.calorieGoal)) kcal")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AltoTheme.textSecondary)
                Spacer()
                Button {
                    viewModel.generateTodayPlan()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text("Pivot plan")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(AltoTheme.primary)
                }
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func activityRow(activity: PlannedActivity) -> some View {
        HStack(spacing: 12) {
            Text(activity.emoji)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(activity.status == .notStarted ? AltoTheme.textSecondary : AltoTheme.textPrimary)
                if !activity.details.isEmpty {
                    Text(activity.details)
                        .font(.system(size: 11))
                        .foregroundStyle(AltoTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()

            activityStatusBadge(activity: activity)
        }
        .padding(12)
        .background(activityBackground(for: activity.status))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func activityStatusBadge(activity: PlannedActivity) -> some View {
        switch activity.status {
        case .done:
            Text("✓ Done")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AltoTheme.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AltoTheme.green.opacity(0.15))
                .clipShape(Capsule())
        case .inProgress:
            Button {
                viewModel.completeWorkoutSession()
            } label: {
                Text("Complete")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AltoTheme.primary)
                    .clipShape(Capsule())
            }
        case .notStarted:
            if viewModel.todayPlan.currentActivity == nil {
                Button {
                    viewModel.startCurrentActivity()
                } label: {
                    Text("▶ Start")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AltoTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AltoTheme.primary.opacity(0.12))
                        .clipShape(Capsule())
                }
            } else {
                Text("Later")
                    .font(.system(size: 11))
                    .foregroundStyle(AltoTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AltoTheme.border.opacity(0.3))
                    .clipShape(Capsule())
            }
        }
    }

    private func activityBackground(for status: ActivityStatus) -> Color {
        switch status {
        case .done: return AltoTheme.green.opacity(0.08)
        case .inProgress: return AltoTheme.primary.opacity(0.08)
        case .notStarted: return AltoTheme.surface
        }
    }

    // MARK: - Voice Log Card

    private var voiceLogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("LOG A WORKOUT")

            ZStack(alignment: .topLeading) {
                if viewModel.voiceTranscript.isEmpty {
                    Text("Describe your workout, e.g. \"I did 30 mins of yoga\"")
                        .font(.system(size: 13))
                        .foregroundStyle(AltoTheme.textSecondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $viewModel.voiceTranscript)
                    .font(.system(size: 13))
                    .foregroundStyle(AltoTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 70, maxHeight: 120)
            }
            .padding(10)
            .background(AltoTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AltoTheme.border, lineWidth: 1))

            HStack(spacing: 10) {
                Button {
                    Task { await viewModel.toggleDictation() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isDictating ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 14))
                        Text(viewModel.isDictating ? "Stop" : "Dictate")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(viewModel.isDictating ? AltoTheme.red : AltoTheme.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        (viewModel.isDictating ? AltoTheme.red : AltoTheme.primary).opacity(0.12)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    viewModel.parseVoiceLog()
                } label: {
                    Text("Parse & Log")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AltoTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.voiceTranscript.isEmpty)
                .opacity(viewModel.voiceTranscript.isEmpty ? 0.5 : 1)

                Spacer()
            }

            if let log = viewModel.lastVoiceLog {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AltoTheme.green)
                        .font(.system(size: 13))
                    Text("Logged: \(log.workoutType) · \(log.durationMinutes) min")
                        .font(.system(size: 12))
                        .foregroundStyle(AltoTheme.green)
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(AltoTheme.red)
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
