import Foundation
import UserNotifications

protocol NotificationService {
    func requestAuthorization() async -> Bool
    func scheduleDailyWellnessCheck(hour: Int, minute: Int) async throws
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
}
