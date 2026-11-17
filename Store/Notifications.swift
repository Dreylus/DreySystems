import Foundation
import UserNotifications
import UIKit

@MainActor final class Notifications: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var permission = "Checking…"
    @Published var pending: [UNNotificationRequest] = []
    @Published var selectedID: String?
    @Published var error: String?
    @Published var busy = false
    private let center = UNUserNotificationCenter.current()
    override init() { super.init(); center.delegate = self }
    func refresh() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized: permission = "Allowed"
        case .provisional: permission = "Quiet delivery"
        case .denied: permission = "Denied — open iOS Settings"
        default: permission = "Not requested"
        }
        pending = await center.pendingNotificationRequests()
        pending.sort { (left: UNNotificationRequest, right: UNNotificationRequest) -> Bool in
            let leftDate: Date = left.nextDeliveryDate ?? Date.distantFuture
            let rightDate: Date = right.nextDeliveryDate ?? Date.distantFuture
            return leftDate < rightDate
        }
    }
    func authorize() async throws {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            guard try await center.requestAuthorization(options: [.alert,.sound,.badge]) else {
                await refresh(); throw DataIssue.invalid("Notifications were not allowed. Enable them in iOS Settings.")
            }
        } else if settings.authorizationStatus == .denied {
            await refresh(); throw DataIssue.invalid("Notifications are disabled. Enable them in iOS Settings.")
        }
        await refresh()
    }
    private func attachment(_ bytes: Data?) throws -> [UNNotificationAttachment] {
        guard let bytes else { return [] }
        guard let image = UIImage(data: bytes), let jpeg = image.jpegData(compressionQuality: 0.85) else {
            throw DataIssue.invalid("The notification image is not a valid image.")
        }
        let folder = URL.cachesDirectory.appending(path: "NotificationImages")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: "\(UUID().uuidString).jpg")
        try jpeg.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        return [try UNNotificationAttachment(identifier: "store-image", url: url)]
    }
    func refill(_ settings: StoreSettings) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            try settings.validate(); try await authorize()
            // Preserve manually scheduled reminders and the test slot. Reserve four slots below 64.
            let old = await center.pendingNotificationRequests()
            let orders = old.filter { $0.identifier.hasPrefix("order.") }
            let others = old.count - orders.count
            var rng = SystemRandomNumberGenerator()
            let plan = try OrderPlanner.plan(settings: settings, now: Date(), capacity: 60-others, rng: &rng)
            guard !plan.isEmpty else { throw DataIssue.invalid("No slots left. Cancel a reminder before starting a batch.") }
            center.removePendingNotificationRequests(withIdentifiers: orders.map(\.identifier))
            var added: [String] = []
            do {
                for (index, order) in plan.enumerated() {
                    let content = UNMutableNotificationContent()
                    content.title = "Order #\(5942 + index)"
                    content.subtitle = "from \(settings.name)"
                    content.body = "\(settings.currency)\(String(format: "%.2f", order.amount)), \(order.items) items from Online Store · \(settings.name)"
                    content.sound = settings.sound ? .default : nil
                    if settings.badge { content.badge = NSNumber(value: index+1) }
                    content.threadIdentifier = "orders"
                    content.userInfo = ["route": order.id]
                    content.attachments = try attachment(settings.image)
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, order.date.timeIntervalSinceNow), repeats: false)
                    try await center.add(UNNotificationRequest(identifier: order.id, content: content, trigger: trigger))
                    added.append(order.id)
                }
            } catch {
                center.removePendingNotificationRequests(withIdentifiers: added)
                throw error
            }
        } catch { self.error = "\(error.localizedDescription) If replacing a batch failed, refill it again." }
        await refresh()
    }
    func schedule(_ reminder: StoreReminder, settings: StoreSettings) async throws {
        guard !busy else { throw DataIssue.invalid("Wait for the current schedule operation to finish.") }
        busy = true; defer { busy = false }
        try reminder.validate()
        guard reminder.enabled else { cancel(reminder.identifier); return }
        guard reminder.nextDate(after: Date()) != nil else { throw DataIssue.invalid("Choose a future date and minute.") }
        try await authorize()
        let requests = await center.pendingNotificationRequests()
        guard requests.filter({ $0.identifier != reminder.identifier }).count < 60 else { throw DataIssue.invalid("The 60-slot budget is full. Cancel an order or reminder first.") }
        let content = UNMutableNotificationContent()
        content.title = reminder.title; content.body = reminder.body
        content.sound = settings.sound ? .default : nil
        if settings.badge { content.badge = 1 }
        content.userInfo = ["route": reminder.identifier]
        try await center.add(UNNotificationRequest(identifier: reminder.identifier, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: reminder.components(), repeats: reminder.rule != .once)))
        await refresh()
    }
    func test(_ settings: StoreSettings) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            try await authorize()
            let content = UNMutableNotificationContent()
            content.title = "Test order from \(settings.name)"; content.body = "Your local notification is working."
            content.sound = settings.sound ? .default : nil
            if settings.badge { content.badge = 1 }
            content.attachments = try attachment(settings.image)
            content.userInfo = ["route": "test"]
            try await center.add(UNNotificationRequest(identifier: "test", content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)))
        } catch { self.error = error.localizedDescription }
        await refresh()
    }
    func cancel(_ id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
        Task { await refresh() }
    }
    func stopOrders() {
        Task {
            let requests = await center.pendingNotificationRequests()
            center.removePendingNotificationRequests(withIdentifiers: requests.filter { $0.identifier.hasPrefix("order.") }.map(\.identifier))
            await refresh()
        }
    }
    func cancelAll() {
        center.removeAllPendingNotificationRequests(); center.removeAllDeliveredNotifications()
        Task { try? await center.setBadgeCount(0); await refresh() }
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner,.sound,.badge,.list])
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        let route = response.notification.request.content.userInfo["route"] as? String ?? response.notification.request.identifier
        Task { @MainActor in self.selectedID = route }
        completionHandler()
    }
}

extension UNNotificationRequest {
    var nextDeliveryDate: Date? {
        if let calendar = trigger as? UNCalendarNotificationTrigger { return calendar.nextTriggerDate() }
        if let interval = trigger as? UNTimeIntervalNotificationTrigger { return interval.nextTriggerDate() }
        return nil
    }
}