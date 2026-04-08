import Foundation
import UserNotifications

protocol NotificationService {
    func requestAuthorization() async -> Bool
    func scheduleDailyWellnessCheck(hour: Int, minute: Int) async throws
    func sendCompassionateReengagement(achievedKcal: Double, plannedKcal: Double) async
    func sendRecoveryDayInserted() async
    func schedulePostWorkoutRPEPrompt(delayMinutes: Int) async
}

enum NotificationServiceError: Error {
    case notAuthorized
}

final class UserNotificationService: NotificationService {
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func scheduleDailyWellnessCheck(hour: Int = 7, minute: Int = 0) async throws {
        let granted = await requestAuthorization()
        guard granted else { throw NotificationServiceError.notAuthorized }

        let content = UNMutableNotificationContent()
        content.title = "Daily Check-In"
        content.body = "10-second readiness check: soreness, stress, motivation."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "alto.dwq.daily",
            content: content,
            trigger: trigger
        )

        try await withCheckedThrowingContinuation { continuation in
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    // Fired when the user achieved < 50% of planned calorie burn.
    func sendCompassionateReengagement(achievedKcal: Double, plannedKcal: Double) async {
        guard await requestAuthorization() else { return }

        let pct = Int((achievedKcal / max(1, plannedKcal) * 100).rounded())
        let content = UNMutableNotificationContent()
        content.title = "Every bit counts 💛"
        content.body = "You hit \(pct)% of today's goal. A 10-minute walk still moves you forward — want to add one?"
        content.sound = .default
        content.userInfo = ["action": "compassionate_reengagement"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "alto.effort.reengagement",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // Fired when a low-RPE session was perceived as very hard — inserts a recovery day.
    func sendRecoveryDayInserted() async {
        guard await requestAuthorization() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Recovery day added 🛌"
        content.body = "That session felt harder than planned. Alto has swapped tomorrow to a rest day — your body will thank you."
        content.sound = .default
        content.userInfo = ["action": "recovery_day_inserted"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "alto.recovery.inserted",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // Schedules a prompt N minutes after workout completion to capture RPE.
    func schedulePostWorkoutRPEPrompt(delayMinutes: Int = 10) async {
        guard await requestAuthorization() else { return }

        let content = UNMutableNotificationContent()
        content.title = "How did that feel?"
        content.body = "Rate your effort so Alto can tune tomorrow's plan."
        content.sound = .default
        content.userInfo = ["action": "rate_rpe"]

        let delay = TimeInterval(max(1, delayMinutes) * 60)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "alto.rpe.prompt",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
