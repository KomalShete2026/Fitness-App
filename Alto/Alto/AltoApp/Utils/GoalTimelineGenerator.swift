import Foundation

enum GoalTimelineGenerator {
    static func generate(targetDate: Date, from startDate: Date = Date()) -> [GoalMilestone] {
        guard targetDate > startDate else {
            let fallback = Calendar.current.date(byAdding: .weekOfYear, value: 8, to: startDate) ?? startDate
            return generate(targetDate: fallback, from: startDate)
        }

        let phases: [MilestonePhase] = [.base, .build, .peak, .taper]
        let totalInterval = targetDate.timeIntervalSince(startDate)
        let phaseInterval = totalInterval / Double(phases.count)

        return phases.enumerated().map { index, phase in
            let phaseStart = startDate.addingTimeInterval(phaseInterval * Double(index))
            let phaseEnd: Date
            if index == phases.count - 1 {
                phaseEnd = targetDate
            } else {
                phaseEnd = startDate.addingTimeInterval(phaseInterval * Double(index + 1))
            }
            return GoalMilestone(phase: phase, startDate: phaseStart, endDate: phaseEnd)
        }
    }
}
