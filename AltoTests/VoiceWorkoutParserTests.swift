import XCTest
@testable import Alto

// MARK: - VoiceWorkoutParser Tests

final class VoiceWorkoutParserTests: XCTestCase {

    var parser: VoiceWorkoutParser!

    override func setUp() {
        super.setUp()
        parser = VoiceWorkoutParser()
    }

    func test_parse_basicYoga_succeeds() {
        let result = parser.parse("I did 30 mins of Yoga")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.durationMinutes, 30)
        XCTAssertTrue(result?.workoutType.lowercased().contains("yoga") ?? false)
    }

    func test_parse_running_succeeds() {
        let result = parser.parse("I did 45 minutes of running")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.durationMinutes, 45)
    }

    func test_parse_emptyString_returnsNil() {
        let result = parser.parse("")
        XCTAssertNil(result)
    }

    func test_parse_noDuration_returnsNil() {
        let result = parser.parse("I did some yoga")
        XCTAssertNil(result)
    }

    func test_parse_capitalisedActivity_succeeds() {
        let result = parser.parse("I did 60 mins of HIIT")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.durationMinutes, 60)
    }

    func test_parse_minutesAbbreviation_succeeds() {
        let result = parser.parse("I did 20 min of Pilates")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.durationMinutes, 20)
    }
}
