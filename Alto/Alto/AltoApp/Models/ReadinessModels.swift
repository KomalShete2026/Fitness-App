import Foundation

struct ReadinessSnapshot {
    let sleepHours: Double?
    let hrv: Double?
    let precipitationProbability: Double?
    let temperatureCelsius: Double?

    var weatherConflict: Bool {
        guard let precipitationProbability else { return false }
        return precipitationProbability > 0.5
    }
}
