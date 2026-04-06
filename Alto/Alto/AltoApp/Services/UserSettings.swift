import Foundation
import SwiftUI

/// Manages user preferences and API configuration
/// All settings are persisted to UserDefaults and automatically saved on change
class UserSettings: ObservableObject {

    // MARK: - API Configuration

    @Published var geminiAPIKey: String {
        didSet {
            UserDefaults.standard.set(geminiAPIKey, forKey: "geminiAPIKey")
        }
    }

    @Published var selectedGeminiModel: GeminiModel {
        didSet {
            UserDefaults.standard.set(selectedGeminiModel.rawValue, forKey: "selectedGeminiModel")
        }
    }

    // MARK: - App Preferences

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    @Published var dailyReminderHour: Int {
        didSet {
            UserDefaults.standard.set(dailyReminderHour, forKey: "dailyReminderHour")
        }
    }

    @Published var dailyReminderMinute: Int {
        didSet {
            UserDefaults.standard.set(dailyReminderMinute, forKey: "dailyReminderMinute")
        }
    }

    // MARK: - Computed Properties

    var isAPIKeyConfigured: Bool {
        !geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var dailyReminderTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var components = DateComponents()
        components.hour = dailyReminderHour
        components.minute = dailyReminderMinute

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(dailyReminderHour):\(String(format: "%02d", dailyReminderMinute))"
    }

    // MARK: - Initialization

    init() {
        // Load API Key
        _geminiAPIKey = Published(
            initialValue: UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        )

        // Load Gemini Model
        let modelString = UserDefaults.standard.string(forKey: "selectedGeminiModel") ?? GeminiModel.flash15.rawValue
        _selectedGeminiModel = Published(
            initialValue: GeminiModel(rawValue: modelString) ?? .flash15
        )

        // Load Notifications
        let notificationsKey = "notificationsEnabled"
        if UserDefaults.standard.object(forKey: notificationsKey) == nil {
            _notificationsEnabled = Published(initialValue: true)
            UserDefaults.standard.set(true, forKey: notificationsKey)
        } else {
            _notificationsEnabled = Published(
                initialValue: UserDefaults.standard.bool(forKey: notificationsKey)
            )
        }

        // Load Daily Reminder Time
        let hour = UserDefaults.standard.integer(forKey: "dailyReminderHour")
        _dailyReminderHour = Published(initialValue: hour == 0 ? 7 : hour)

        _dailyReminderMinute = Published(
            initialValue: UserDefaults.standard.integer(forKey: "dailyReminderMinute")
        )
    }

    // MARK: - Methods

    /// Clears all user settings (useful for logout or reset)
    func clearAllSettings() {
        geminiAPIKey = ""
        selectedGeminiModel = .flash15
        notificationsEnabled = true
        dailyReminderHour = 7
        dailyReminderMinute = 0
    }
}

// MARK: - Gemini Model Configuration

enum GeminiModel: String, Codable, CaseIterable {
    case flash15 = "gemini-1.5-flash"
    case flash20 = "gemini-2.0-flash-exp"
    case pro15 = "gemini-1.5-pro"

    var displayName: String {
        switch self {
        case .flash15: return "Gemini 1.5 Flash"
        case .flash20: return "Gemini 2.0 Flash"
        case .pro15: return "Gemini 1.5 Pro"
        }
    }

    var description: String {
        switch self {
        case .flash15:
            return "Fast and efficient. Best for daily use. Free tier: 15 RPM."
        case .flash20:
            return "Latest experimental model. Faster responses."
        case .pro15:
            return "Most capable. Better analysis quality. Free tier: 2 RPM."
        }
    }

    var icon: String {
        switch self {
        case .flash15: return "⚡"
        case .flash20: return "✨"
        case .pro15: return "🧠"
        }
    }

    var apiEndpoint: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(rawValue):generateContent"
    }
}
