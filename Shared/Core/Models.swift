import Foundation

protocol CheckedData: Codable { func validate() throws }
enum DataIssue: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case .invalid(let text) = self { return text }; return nil }
}
enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case once, daily, weekly
    var id: String { rawValue }
}
struct StoreSettings: CheckedData {
    var name = "Store"
    var currency = "$"
    var minimumGap = 30.0
    var maximumGap = 180.0
    var minimumAmount = 10.0
    var maximumAmount = 150.0
    var batchSize = 30
    var sound = true
    var badge = true
    var image: Data?
    var reminders: [StoreReminder] = []
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              name.count <= 100, currency.count <= 12,
              minimumGap.isFinite, maximumGap.isFinite,
              minimumGap >= 5, maximumGap >= minimumGap, maximumGap <= 604800,
              minimumAmount.isFinite, maximumAmount.isFinite,
              minimumAmount >= 0, maximumAmount >= minimumAmount, maximumAmount <= 1e9,
              (1...60).contains(batchSize), reminders.count <= 60,
              Set(reminders.map(\.id)).count == reminders.count,
              (image?.count ?? 0) <= 5_000_000 else {
            throw DataIssue.invalid("Check the name, interval (5 seconds–7 days), amount range, and batch (1–60).")
        }
        for reminder in reminders { try reminder.validate() }
    }
}
struct StoreReminder: Codable, Identifiable, Equatable {
    var id = UUID()
    var title = "Order reminder"
    var body = "Take a moment to work on your store."
    var date = Date().addingTimeInterval(3600)
    var rule = RepeatRule.once
    var enabled = true
    var identifier: String { "reminder.\(id.uuidString)" }
    func validate() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              title.count <= 200, body.count <= 2000, date.timeIntervalSince1970.isFinite else {
            throw DataIssue.invalid("Enter a title and a valid date.")
        }
    }
    // Floating local wall-clock time; follows the phone's current time zone and DST.
    func components(calendar: Calendar = .current) -> DateComponents {
        let fields: Set<Calendar.Component> = rule == .once ? [.year,.month,.day,.hour,.minute] :
            rule == .daily ? [.hour,.minute] : [.weekday,.hour,.minute]
        return calendar.dateComponents(fields, from: date)
    }
    func nextDate(after now: Date, calendar: Calendar = .current) -> Date? {
        if rule == .once {
            guard let rounded = calendar.date(from: components(calendar: calendar)), rounded > now else { return nil }
            return rounded
        }
        return calendar.nextDate(after: now, matching: components(calendar: calendar),
                                 matchingPolicy: .nextTime, repeatedTimePolicy: .first)
    }
}
struct PlannedOrder: Identifiable, Equatable {
    let id: String
    let date: Date
    let amount: Double
    let items: Int
}
enum OrderPlanner {
    static func plan<R: RandomNumberGenerator>(settings: StoreSettings, now: Date,
                                               capacity: Int, rng: inout R) throws -> [PlannedOrder] {
        try settings.validate()
        var date = now
        return (0..<min(settings.batchSize, max(0, capacity))).map { index in
            date = date.addingTimeInterval(Double.random(in: settings.minimumGap...settings.maximumGap, using: &rng))
            return PlannedOrder(id: "order.\(UUID().uuidString)", date: date,
                                amount: Double.random(in: settings.minimumAmount...settings.maximumAmount, using: &rng),
                                items: Int.random(in: 1...5, using: &rng))
        }
    }
}
enum MetricStatus: String, Codable, CaseIterable, Identifiable {
    case automatic, up, down, check, warning, none
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .automatic, .down: return "arrow.down.circle.fill"
        case .up: return "arrow.up.circle.fill"
        case .check: return "checkmark.circle"
        case .warning: return "exclamationmark.circle"
        case .none: return ""
        }
    }
}
struct Metric: Codable, Identifiable {
    var id = UUID()
    var title: String
    var value: Double
    var status = MetricStatus.down
}
struct Video: Codable, Identifiable {
    var id = UUID()
    var title = "Untitled video"
    var kind = "Short"
    var age = "First 1 day"
    var views = 0.0
    var likes = 0
    var commentCount = 0
    var thumbnail: Data?
}
struct Comment: Codable, Identifiable {
    var id = UUID()
    var author = "Viewer"
    var age = "Today"
    var text = "Great video!"
    var reply = ""
    var hearted = false
}
struct HubData: CheckedData {
    var channel = "Smoreh"
    var subscribers = 89137
    var currency = "MX$"
    var appearance = "system"
    var avatar: Data?
    var metrics: [String: [Metric]] = Dictionary(uniqueKeysWithValues: [7,28,90,365].map { day in
        (String(day), [Metric(title: "Views", value: 234600 * Double(day)/28),
                       Metric(title: "Watch time (hours)", value: 736 * Double(day)/28),
                       Metric(title: "Subscribers", value: 67 * Double(day)/28),
                       Metric(title: "Estimated revenue", value: 318 * Double(day)/28, status: .check)])
    })
    var videos = [Video(title: "Nosey Animatronic ☠️ #horror", age: "First 425 days 12 hours", views: 41000, likes: 643, commentCount: 70),
                  Video(title: "Minecraft Horror Mods ☠️", age: "First 431 days 9 hours", views: 958000, likes: 10000, commentCount: 124)]
    var comments = [Comment(author: "B o n", age: "2w ago", text: "That caught me off guard!"),
                    Comment(author: "M", age: "7d ago", text: "bro make it more shaky")]
    var payoutGoal = 1000.0
    func validate() throws {
        guard !channel.isEmpty, channel.count <= 100, subscribers >= 0,
              currency.count <= 12, ["system","light","dark"].contains(appearance),
              payoutGoal.isFinite, payoutGoal > 0,
              Set(metrics.keys) == Set(["7","28","90","365"]),
              metrics.values.allSatisfy({ $0.count == 4 && Set($0.map(\.id)).count == 4 && $0.allSatisfy { $0.value.isFinite && $0.value >= 0 } }),
              videos.count <= 1000, comments.count <= 5000,
              Set(videos.map(\.id)).count == videos.count, Set(comments.map(\.id)).count == comments.count,
              videos.allSatisfy({ !$0.title.isEmpty && $0.views.isFinite && $0.views >= 0 && $0.likes >= 0 && $0.commentCount >= 0 && ($0.thumbnail?.count ?? 0) <= 5_000_000 }),
              (avatar?.count ?? 0) <= 5_000_000 else { throw DataIssue.invalid("The backup contains invalid dashboard data.") }
    }
}
enum LocalJSON {
    static func encode<T: CheckedData>(_ data: T) throws -> Data {
        try data.validate()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(data)
    }
    static func decode<T: CheckedData>(_ type: T.Type, from data: Data) throws -> T {
        let value = try JSONDecoder().decode(type, from: data); try value.validate(); return value
    }
    static func save<T: CheckedData>(_ data: T, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encode(data).write(to: url, options: .atomic)
    }
}
