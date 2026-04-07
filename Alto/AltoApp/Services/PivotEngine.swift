import Foundation

enum PivotEngine {
    static func evaluate(sleepHours: Double?, rainProbability: Double?) -> PivotDecision {
        var reasons: [String] = []

        if let sleepHours, sleepHours < 6.5 {
            reasons.append("Sleep was \(String(format: "%.1f", sleepHours))h (< 6.5h).")
        }

        if let rainProbability, rainProbability > 0.5 {
            reasons.append("Rain probability is \(Int((rainProbability * 100).rounded()))% (> 50%).")
        }

        return PivotDecision(shouldPivot: !reasons.isEmpty, reasons: reasons)
    }

    static func nextHighReadinessDate(from projections: [DailyProjection], after referenceDate: Date) -> Date? {
        projections
            .filter { $0.date >= referenceDate && $0.isHighReadiness }
            .sorted { $0.date < $1.date }
            .first?
            .date
    }
}
