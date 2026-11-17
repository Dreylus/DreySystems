import XCTest
@testable import FactoryCore

final class FactoryCoreTests: XCTestCase {
    struct Seeded: RandomNumberGenerator {
        var state: UInt64 = 42
        mutating func next() -> UInt64 { state = state &* 6364136223846793005 &+ 1442695040888963407; return state }
    }
    func testRandomBatchBoundsAndCapacity() throws {
        var settings = StoreSettings(); settings.batchSize = 60
        var rng = Seeded(); let now = Date(timeIntervalSince1970: 1800000000)
        let orders = try OrderPlanner.plan(settings: settings, now: now, capacity: 9, rng: &rng)
        XCTAssertEqual(orders.count, 9)
        XCTAssertEqual(Set(orders.map(\.id)).count, 9)
        var previous = now
        for order in orders {
            let gap = order.date.timeIntervalSince(previous)
            XCTAssertGreaterThanOrEqual(gap, settings.minimumGap)
            XCTAssertLessThanOrEqual(gap, settings.maximumGap)
            XCTAssertTrue((settings.minimumAmount...settings.maximumAmount).contains(order.amount))
            XCTAssertTrue((1...5).contains(order.items)); previous = order.date
        }
        XCTAssertEqual(try OrderPlanner.plan(settings: settings, now: now, capacity: -1, rng: &rng).count, 0)
    }
    func testInvalidRangesRejected() {
        var settings = StoreSettings(); settings.maximumGap = 1
        XCTAssertThrowsError(try settings.validate())
        settings = StoreSettings(); settings.minimumAmount = .nan
        XCTAssertThrowsError(try settings.validate())
        settings = StoreSettings(); settings.batchSize = 65
        XCTAssertThrowsError(try settings.validate())
    }
    func testReminderIdentityStableAcrossEdits() throws {
        var reminder = StoreReminder(); let id = reminder.identifier
        reminder.title = "Changed"; reminder.rule = .weekly
        XCTAssertEqual(id, reminder.identifier)
        var settings = StoreSettings(); settings.reminders = [reminder,reminder]
        XCTAssertThrowsError(try settings.validate())
    }
    func testCreateEditDeleteRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("store.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var settings = StoreSettings(); settings.reminders.append(StoreReminder())
        settings.reminders[0].title = "Edited"
        try LocalJSON.save(settings, to: url)
        var loaded = try LocalJSON.decode(StoreSettings.self, from: Data(contentsOf: url))
        XCTAssertEqual(loaded.reminders[0].title, "Edited")
        loaded.reminders.removeAll(); try LocalJSON.save(loaded, to: url)
        XCTAssertTrue(try LocalJSON.decode(StoreSettings.self, from: Data(contentsOf: url)).reminders.isEmpty)
    }
    func testCalendarRecurrenceAndPastDate() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 10))!
        var reminder = StoreReminder(); reminder.date = now.addingTimeInterval(-3600)
        XCTAssertNil(reminder.nextDate(after: now, calendar: calendar))
        reminder.rule = .daily
        XCTAssertEqual(calendar.component(.hour, from: try XCTUnwrap(reminder.nextDate(after: now, calendar: calendar))), 9)
        XCTAssertNil(reminder.components(calendar: calendar).weekday)
        reminder.rule = .weekly
        XCTAssertEqual(reminder.components(calendar: calendar).weekday, 2)
        XCTAssertEqual(calendar.component(.weekday, from: try XCTUnwrap(reminder.nextDate(after: now, calendar: calendar))), 2)
    }
    func testDSTSkipsNonexistentWallClockTime() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        var reminder = StoreReminder(); reminder.rule = .daily
        reminder.date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 2, minute: 30))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 0))!
        let next = try XCTUnwrap(reminder.nextDate(after: now, calendar: calendar))
        XCTAssertGreaterThan(next, now)
        XCTAssertEqual(calendar.component(.day, from: next), 8)
        XCTAssertEqual(calendar.component(.hour, from: next), 3)
    }
    func testHubRangesAndEditsPersist() throws {
        var hub = HubData(); let original = hub.metrics["7"]![0].value
        hub.metrics["28"]![0].value = 123
        hub.comments[0].reply = "Thanks!"; hub.comments[0].hearted = true
        let loaded = try LocalJSON.decode(HubData.self, from: LocalJSON.encode(hub))
        XCTAssertEqual(loaded.metrics["7"]![0].value, original)
        XCTAssertEqual(loaded.metrics["28"]![0].value, 123)
        XCTAssertEqual(loaded.comments[0].reply, "Thanks!")
        XCTAssertTrue(loaded.comments[0].hearted)
    }
    func testCorruptBackupRejected() {
        XCTAssertThrowsError(try LocalJSON.decode(HubData.self, from: Data("{}".utf8)))
        var hub = HubData(); hub.metrics.removeValue(forKey: "28")
        XCTAssertThrowsError(try LocalJSON.encode(hub))
    }
}
