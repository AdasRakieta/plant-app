import XCTest
@testable import Pedy

final class CarePlannerTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func day(_ number: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: number))!
    }

    func testOverlappingWindowsGroupWithinBounds() {
        let a = CareWindow(id: UUID(), plantID: UUID(), plantName: "A", earliest: day(2), latest: day(4))
        let b = CareWindow(id: UUID(), plantID: UUID(), plantName: "B", earliest: day(3), latest: day(5))

        let sessions = CarePlanner.sessions(for: [a, b], preferredWeekday: 7, calendar: calendar)

        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].date, day(3))
        XCTAssertEqual(Set(sessions[0].tasks.map(\.id)), Set([a.id, b.id]))
    }

    func testNonOverlappingWindowStaysSeparate() {
        let urgent = CareWindow(id: UUID(), plantID: UUID(), plantName: "Pilna", earliest: day(1), latest: day(1))
        let later = CareWindow(id: UUID(), plantID: UUID(), plantName: "Później", earliest: day(3), latest: day(4))

        let sessions = CarePlanner.sessions(for: [urgent, later], calendar: calendar)

        XCTAssertEqual(sessions.map(\.date), [day(1), day(3)])
        XCTAssertEqual(sessions.flatMap(\.tasks).count, 2)
    }

    func testPreferenceNeverPushesPastLatestDay() {
        let task = CareWindow(id: UUID(), plantID: UUID(), plantName: "A", earliest: day(1), latest: day(2))
        let sessions = CarePlanner.sessions(for: [task], preferredWeekday: 7, calendar: calendar)

        XCTAssertEqual(sessions.count, 1)
        XCTAssertLessThanOrEqual(sessions[0].date, task.latest)
    }

    func testNextCheckHasMinimumOneDayInterval() {
        XCTAssertEqual(CarePlanner.nextCheck(after: day(1), intervalDays: 0, calendar: calendar), day(2))
        XCTAssertEqual(CarePlanner.nextCheck(after: day(1), intervalDays: 3, calendar: calendar), day(4))
    }
}
