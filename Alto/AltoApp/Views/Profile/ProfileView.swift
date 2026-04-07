import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var userSettings: UserSettings
    @State private var showSettings = false

    var body: some View {
        ZStack {
            AltoTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    profileCard
                    apiStatusCard
                    healthCard
                    connectedCard
                    settingsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(userSettings)
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .stroke(AltoTheme.primary, lineWidth: 3)
                    .frame(width: 80, height: 80)
                Text("🧑")
                    .font(.system(size: 40))
            }

            VStack(spacing: 4) {
                Text(userStore.userName)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(AltoTheme.textPrimary)
                Text("Training since \(formattedDate(userStore.goalStartDate))")
                    .font(.system(size: 12))
                    .foregroundStyle(AltoTheme.textSecondary)
            }

            // Stat chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    statChip(label: "Age", value: "\(userStore.age)")
                    statChip(label: "Height", value: userStore.heightFeetDisplay)
                    statChip(label: "Weight", value: "\(userStore.weightLb) lb")
                    statChip(label: "Frequency", value: "\(userStore.activityFrequencyValue)x/\(userStore.activityFrequencyUnit)")
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func statChip(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AltoTheme.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(AltoTheme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AltoTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AltoTheme.border, lineWidth: 1))
    }

    // MARK: - API Status Card

    private var apiStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("AI FEATURES")

            HStack(spacing: 12) {
                Image(systemName: userSettings.isAPIKeyConfigured ? "sparkles" : "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(userSettings.isAPIKeyConfigured ? AltoTheme.primary : AltoTheme.red)
                    .frame(width: 32, height: 32)
                    .background((userSettings.isAPIKeyConfigured ? AltoTheme.primary : AltoTheme.red).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(userSettings.isAPIKeyConfigured ? "AI Coaching Active" : "Setup Required")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AltoTheme.textPrimary)

                    Text(userSettings.isAPIKeyConfigured
                         ? "\(userSettings.selectedGeminiModel.displayName) • Ready"
                         : "Tap to configure Gemini API key")
                        .font(.system(size: 12))
                        .foregroundStyle(AltoTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AltoTheme.border)
            }
            .padding(14)
            .background(userSettings.isAPIKeyConfigured ? AltoTheme.primary.opacity(0.05) : AltoTheme.red.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(userSettings.isAPIKeyConfigured ? AltoTheme.primary.opacity(0.2) : AltoTheme.red.opacity(0.2), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                showSettings = true
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Health Card

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("HEALTH PROFILE")
                .padding(.bottom, 4)

            settingRow(
                icon: "heart.fill",
                iconColor: AltoTheme.red,
                label: "Health Conditions",
                value: userStore.healthConditions.isEmpty ? "None" : userStore.healthConditions.joined(separator: ", ")
            )
            Divider().background(AltoTheme.border)
            settingRow(
                icon: "figure.run",
                iconColor: AltoTheme.primary,
                label: "Preferred Workouts",
                value: userStore.preferredWorkouts.isEmpty ? "Not set" : userStore.preferredWorkouts.joined(separator: ", ")
            )
            Divider().background(AltoTheme.border)
            settingRow(
                icon: "flame.fill",
                iconColor: AltoTheme.primary,
                label: "Activity Frequency",
                value: "\(userStore.activityFrequencyValue)x / \(userStore.activityFrequencyUnit)"
            )
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Connected Card

    private var connectedCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("CONNECTED APPS")
                .padding(.bottom, 4)

            connectedRow(icon: "heart.fill", iconColor: AltoTheme.red, label: "Apple Health")
            Divider().background(AltoTheme.border)
            connectedRow(icon: "applewatch", iconColor: AltoTheme.textSecondary, label: "Apple Watch")
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func connectedRow(icon: String, iconColor: Color, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(AltoTheme.textPrimary)

            Spacer()

            Text("Connected")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AltoTheme.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AltoTheme.green.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    // MARK: - Settings Card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("SETTINGS")
                .padding(.bottom, 4)

            Button {
                showSettings = true
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            } label: {
                settingRow(icon: "gearshape.fill", iconColor: AltoTheme.primary, label: "App Settings", value: "")
            }
            .buttonStyle(.plain)

            Divider().background(AltoTheme.border)
            settingRow(icon: "bell.fill", iconColor: AltoTheme.primary, label: "Notifications", value: userSettings.notificationsEnabled ? "On" : "Off")
            Divider().background(AltoTheme.border)
            settingRow(icon: "clock.fill", iconColor: Color(red: 0.37, green: 0.64, blue: 0.98), label: "Daily Reminders", value: userSettings.dailyReminderTime)
            Divider().background(AltoTheme.border)
            settingRow(icon: "lock.shield.fill", iconColor: AltoTheme.green, label: "Data Privacy", value: "Local Only")
            Divider().background(AltoTheme.border)

            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15))
                        .foregroundStyle(AltoTheme.red)
                        .frame(width: 28, height: 28)
                        .background(AltoTheme.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 7))

                    Text("Sign Out")
                        .font(.system(size: 14))
                        .foregroundStyle(AltoTheme.red)

                    Spacer()
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(AltoTheme.textPrimary)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundStyle(AltoTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AltoTheme.border)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(AltoTheme.primary)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}
