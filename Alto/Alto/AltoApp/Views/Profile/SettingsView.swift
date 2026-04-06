import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: UserSettings
    @Environment(\.dismiss) var dismiss

    @State private var showAPIKeyInfo = false
    @State private var showDeleteConfirmation = false
    @State private var apiKeyVisible = false

    var body: some View {
        NavigationView {
            ZStack {
                AltoTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        apiKeySection
                        modelSection
                        notificationsSection
                        aboutSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AltoTheme.primary)
                }
            }
            .alert("Get Gemini API Key", isPresented: $showAPIKeyInfo) {
                Button("Open Google AI Studio") {
                    if let url = URL(string: "https://aistudio.google.com/apikey") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("1. Visit aistudio.google.com/apikey\n2. Sign in with Google\n3. Create API Key\n4. Paste it here\n\nFree tier: 15 requests/minute")
            }
            .alert("Clear API Key", isPresented: $showDeleteConfirmation) {
                Button("Clear", role: .destructive) {
                    settings.geminiAPIKey = ""
                    HapticFeedback.light()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove your API key. You'll need to re-enter it to use AI features.")
            }
        }
    }

    // MARK: - API Key Section

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("GEMINI API KEY")

            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    if apiKeyVisible {
                        TextField("Enter API Key", text: $settings.geminiAPIKey)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(AltoTheme.textPrimary)
                    } else {
                        SecureField("Enter API Key", text: $settings.geminiAPIKey)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(AltoTheme.textPrimary)
                    }

                    Button {
                        apiKeyVisible.toggle()
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: apiKeyVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AltoTheme.textSecondary)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AltoTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(settings.isAPIKeyConfigured ? AltoTheme.green : AltoTheme.border, lineWidth: 1)
                )

                HStack(spacing: 8) {
                    Button {
                        showAPIKeyInfo = true
                        HapticFeedback.light()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 13))
                            Text("How to get API key")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(AltoTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AltoTheme.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    if settings.isAPIKeyConfigured {
                        Button {
                            showDeleteConfirmation = true
                            HapticFeedback.light()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                Text("Clear")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(AltoTheme.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AltoTheme.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            // Status indicator
            HStack(spacing: 6) {
                Image(systemName: settings.isAPIKeyConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(settings.isAPIKeyConfigured ? AltoTheme.green : AltoTheme.red)

                Text(settings.isAPIKeyConfigured ? "API key configured — AI features enabled" : "API key required for AI coaching and meal analysis")
                    .font(.system(size: 12))
                    .foregroundStyle(settings.isAPIKeyConfigured ? AltoTheme.green : AltoTheme.textSecondary)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Model Section

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("AI MODEL")

            Picker("AI Model", selection: $settings.selectedGeminiModel) {
                ForEach(GeminiModel.allCases, id: \.self) { model in
                    HStack {
                        Text(model.icon)
                        Text(model.displayName)
                    }
                    .tag(model)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AltoTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AltoTheme.border, lineWidth: 1))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(settings.selectedGeminiModel.icon)
                        .font(.system(size: 16))
                    Text(settings.selectedGeminiModel.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AltoTheme.textPrimary)
                }

                Text(settings.selectedGeminiModel.description)
                    .font(.system(size: 12))
                    .foregroundStyle(AltoTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(AltoTheme.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("NOTIFICATIONS")

            Toggle(isOn: $settings.notificationsEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AltoTheme.primary)
                        .frame(width: 28, height: 28)
                        .background(AltoTheme.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 7))

                    Text("Daily Wellness Check")
                        .font(.system(size: 14))
                        .foregroundStyle(AltoTheme.textPrimary)
                }
            }
            .tint(AltoTheme.primary)

            if settings.notificationsEnabled {
                Divider().background(AltoTheme.border)

                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(red: 0.37, green: 0.64, blue: 0.98))
                        .frame(width: 28, height: 28)
                        .background(Color(red: 0.37, green: 0.64, blue: 0.98).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 7))

                    Text("Reminder Time")
                        .font(.system(size: 14))
                        .foregroundStyle(AltoTheme.textPrimary)

                    Spacer()

                    Text(settings.dailyReminderTime)
                        .font(.system(size: 13))
                        .foregroundStyle(AltoTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("ABOUT")

            VStack(spacing: 0) {
                infoRow(label: "Version", value: "1.0.0")
                Divider().background(AltoTheme.border)
                infoRow(label: "AI Provider", value: "Google Gemini")
            }
        }
        .padding(16)
        .background(AltoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AltoTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(AltoTheme.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(AltoTheme.textSecondary)
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(AltoTheme.primary)
    }
}

// MARK: - Haptic Feedback Helper

enum HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
