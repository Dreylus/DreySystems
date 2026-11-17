import SwiftUI
import UserNotifications

@main struct StoreApp: App {
    @StateObject private var store = DiskStore(StoreSettings(), filename: "store.json")
    @StateObject private var notifications = Notifications()
    var body: some Scene {
        WindowGroup { StoreRoot(store: store, notifications: notifications).tint(.indigo) }
    }
}
struct StoreRoot: View {
    @ObservedObject var store: DiskStore<StoreSettings>
    @ObservedObject var notifications: Notifications
    @Environment(\.scenePhase) private var scene
    @State private var tab = 0
    @State private var editing: StoreReminder?
    @State private var newReminder = false
    @State private var confirmCancel = false
    @State private var tappedRequest: String?
    var body: some View {
        TabView(selection: $tab) {
            homeTab.tabItem { Label("Home", systemImage: "square.grid.2x2") }.tag(0)
            upcomingTab.tabItem { Label("Upcoming", systemImage: "calendar") }.tag(1)
            NavigationStack { settings }.tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(2)
        }
        .task { await notifications.refresh() }
        .onChange(of: scene) { _, phase in
            if phase == .active { Task { await notifications.refresh(); try? await UNUserNotificationCenter.current().setBadgeCount(0) } }
        }
        .onChange(of: notifications.selectedID, initial: true) { _, id in
            guard let id else { return }; tab = 1
            if let reminder = store.data.reminders.first(where: { $0.identifier == id }) { editing = reminder }
            else { tappedRequest = id }
            notifications.selectedID = nil
        }
        .sheet(item: $editing) { reminder in ReminderEditor(store: store, notifications: notifications, draft: reminder) }
        .sheet(isPresented: $newReminder) { ReminderEditor(store: store, notifications: notifications, draft: StoreReminder()) }
        .alert("Local alert opened", isPresented: Binding(get: { tappedRequest != nil }, set: { if !$0 { tappedRequest = nil } })) {
            Button("OK") { tappedRequest = nil }
        } message: { Text("This alert came from your personal simulation. See Upcoming for the remaining queue.") }
        .errorAlert(Binding(get: { store.error ?? notifications.error }, set: { value in
            if value == nil { store.error = nil; notifications.error = nil }
        }))
    }
    var homeTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        LocalImage(data: store.data.image, symbol: "bag").frame(width: 66, height: 66).clipShape(RoundedRectangle(cornerRadius: 18))
                        VStack(alignment: .leading) { Text(store.data.name).font(.largeTitle.bold()); Text("Your next chapter starts here.").foregroundStyle(.secondary) }
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        Label("PERSONAL SIMULATION", systemImage: "sparkles").font(.caption.bold()).foregroundStyle(.indigo)
                        Text("A little momentum.").font(.title.bold())
                        Text("Schedule a randomized batch of order alerts, then keep building.").foregroundStyle(.secondary)
                        Button { Task { await notifications.refill(store.data) } } label: {
                            Label(notifications.busy ? "Scheduling…" : "Start / refill batch", systemImage: "play.fill").frame(maxWidth: .infinity)
                        }.buttonStyle(.borderedProminent).disabled(notifications.busy)
                        Button("Stop order alerts", role: .destructive) { notifications.stopOrders() }.disabled(notifications.busy)
                    }.card()
                    HStack {
                        stat("Queued", "\(notifications.pending.count)")
                        stat("Random gap", "\(store.data.minimumGap.formatted(.number.precision(.fractionLength(0))))–\(store.data.maximumGap.formatted(.number.precision(.fractionLength(0))))s")
                    }
                    Text("Queued alerts can arrive while locked or closed. When the batch runs out, reopen and refill. iOS controls delivery timing, grouping, sound, and Focus.").font(.footnote).foregroundStyle(.secondary)
                    Button("Send test in 10 seconds", systemImage: "bell.badge") { Task { await notifications.test(store.data) } }.buttonStyle(.bordered).disabled(notifications.busy)
                }.padding()
            }.background(Color(uiColor: .systemGroupedBackground)).navigationTitle("Store").navigationBarTitleDisplayMode(.inline)
        }
    }
    var upcomingTab: some View {
        NavigationStack {
            List {
                Section("Scheduled reminders") {
                    ForEach(store.data.reminders) { reminder in
                        Button { editing = reminder } label: {
                            VStack(alignment: .leading) { Text(reminder.title); Text("\(reminder.rule.rawValue.capitalized) · \(reminder.enabled ? "Enabled" : "Paused")").font(.caption).foregroundStyle(.secondary) }
                        }
                    }.onDelete { offsets in
                        for i in offsets { notifications.cancel(store.data.reminders[i].identifier) }
                        store.data.reminders.remove(atOffsets: offsets)
                    }
                    Button("Add reminder", systemImage: "plus") { newReminder = true }
                }
                Section("Upcoming notification requests") {
                    if notifications.pending.isEmpty { Text("Nothing queued. Start a batch or add a reminder.").foregroundStyle(.secondary) }
                    ForEach(notifications.pending, id: \.identifier) { request in
                        VStack(alignment: .leading) {
                            Text(request.content.title)
                            if let date = request.nextDeliveryDate { Text(date.formatted(date: .abbreviated, time: .shortened)) }
                        }.font(.subheadline).swipeActions { Button("Cancel", role: .destructive) { notifications.cancel(request.identifier) } }
                    }
                }
            }.navigationTitle("Upcoming").refreshable { await notifications.refresh() }
        }
    }
    func stat(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) { Text(name).foregroundStyle(.secondary); Text(value).font(.title3.bold()).minimumScaleFactor(0.5) }.card()
    }
    var settings: some View {
        Form {
            Section("Store identity") {
                TextField("Store name", text: $store.data.name)
                TextField("Currency symbol", text: $store.data.currency)
                PhotoControl(data: $store.data.image, label: "Notification attachment / store image")
                if store.data.image != nil { Button("Remove image", role: .destructive) { store.data.image = nil } }
                Text("The installed app stays named Store. Your custom name appears inside alerts. Photos appear as attachments; iOS chooses their layout.").font(.footnote)
            }
            Section("Random batch") {
                number("Minimum gap (seconds)", $store.data.minimumGap)
                number("Maximum gap (seconds)", $store.data.maximumGap)
                number("Minimum amount", $store.data.minimumAmount)
                number("Maximum amount", $store.data.maximumAmount)
                Stepper("Alerts per batch: \(store.data.batchSize)", value: $store.data.batchSize, in: 1...60)
                Text("Settings apply to the next refill. A 60-slot budget includes reminders; 4 iOS slots remain reserved.").font(.footnote)
            }
            Section("Notifications") {
                LabeledContent("Permission", value: notifications.permission)
                Toggle("Sound", isOn: $store.data.sound)
                Toggle("Badge", isOn: $store.data.badge)
                Button("Request permission") { Task { do { try await notifications.authorize() } catch { notifications.error = error.localizedDescription } } }
                Button("Open iOS notification settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                Button("Test in 10 seconds") { Task { await notifications.test(store.data) } }.disabled(notifications.busy)
                Button("Cancel all alerts", role: .destructive) { confirmCancel = true }.disabled(notifications.busy)
            }
            Section("On-device data") {
                BackupControls(store: store, filename: "Store-backup") { notifications.cancelAll() }
                Text("Import cancels the existing queue. Refill orders or save each imported reminder to schedule it.").font(.footnote)
            }
        }.navigationTitle("Settings")
        .confirmationDialog("Cancel every pending alert? Saved reminders remain available.", isPresented: $confirmCancel) { Button("Cancel all", role: .destructive) { notifications.cancelAll() } }
    }
    func number(_ label: String, _ value: Binding<Double>) -> some View {
        HStack { Text(label); Spacer(); TextField(label, value: value, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 110) }
    }
}
struct ReminderEditor: View {
    @ObservedObject var store: DiskStore<StoreSettings>
    @ObservedObject var notifications: Notifications
    @State var draft: StoreReminder
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $draft.title)
                TextField("Description", text: $draft.body, axis: .vertical)
                DatePicker("Date and time", selection: $draft.date)
                Picker("Repeat", selection: $draft.rule) { ForEach(RepeatRule.allCases) { Text($0.rawValue.capitalized).tag($0) } }
                Toggle("Enabled", isOn: $draft.enabled)
                Text("Daily and weekly alerts follow local wall-clock time. Weekly uses the weekday of the chosen date.").font(.footnote)
            }.navigationTitle("Reminder").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") {
                    Task {
                        do {
                            try await notifications.schedule(draft, settings: store.data)
                            if let i = store.data.reminders.firstIndex(where: { $0.id == draft.id }) { store.data.reminders[i] = draft }
                            else { store.data.reminders.append(draft) }
                            dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                }.disabled(notifications.busy) }
            }.errorAlert($error)
        }
    }
}