import XCTest
@testable import Alto

// MARK: - GoalTimeline + UserStore Tests

final class GoalTimelineTests: XCTestCase {

    // MARK: - GoalTimelineGenerator

    func test_generate_produces4Milestones() {
        let start  = Date()
        let target = Calendar.current.date(byAdding: .month, value: 4, to: start)!
        let milestones = GoalTimelineGenerator.generate(targetDate: target, from: start)
        XCTAssertEqual(milestones.count, 4)
    }

    func test_generate_phasesInCorrectOrder() {
        let start  = Date()
        let target = Calendar.current.date(byAdding: .month, value: 4, to: start)!
        let milestones = GoalTimelineGenerator.generate(targetDate: target, from: start)
        XCTAssertEqual(milestones[0].phase, .base)
        XCTAssertEqual(milestones[1].phase, .build)
        XCTAssertEqual(milestones[2].phase, .peak)
        XCTAssertEqual(milestones[3].phase, .taper)
    }

    func test_generate_noOverlap() {
        let start  = Date()
        let target = Calendar.current.date(byAdding: .month, value: 6, to: start)!
        let milestones = GoalTimelineGenerator.generate(targetDate: target, from: start)

        for i in 0..<(milestones.count - 1) {
            XCTAssertLessThanOrEqual(
                milestones[i].endDate,
                milestones[i+1].startDate,
                "Phase \(i) overlaps with phase \(i+1)"
            )
        }
    }

    func test_generate_coversFullTimeline() {
        let start  = Date()
        let target = Calendar.current.date(byAdding: .month, value: 4, to: start)!
        let milestones = GoalTimelineGenerator.generate(targetDate: target, from: start)

        let firstStart = milestones.first!.startDate
        let lastEnd    = milestones.last!.endDate

        XCTAssertEqual(
            firstStart.timeIntervalSince1970,
            start.timeIntervalSince1970,
            accuracy: 1.0
        )
        XCTAssertEqual(
            lastEnd.timeIntervalSince1970,
            target.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    func test_generate_shortTimeline_stillProduces4Phases() {
        let start  = Date()
        let target = Calendar.current.date(byAdding: .weekOfYear, value: 4, to: start)!
        let milestones = GoalTimelineGenerator.generate(targetDate: target, from: start)
        XCTAssertEqual(milestones.count, 4)
    }
}
