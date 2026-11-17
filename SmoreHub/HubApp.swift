import SwiftUI
import Charts

@main struct HubApp: App {
    @StateObject private var store = DiskStore(HubData(), filename: "hub.json")
    var body: some Scene {
        WindowGroup {
            HubRoot(store: store).tint(.red)
                .preferredColorScheme(store.data.appearance == "system" ? nil : store.data.appearance == "dark" ? .dark : .light)
        }
    }
}
struct HubRoot: View {
    @ObservedObject var store: DiskStore<HubData>
    @State private var tab = 0
    @State private var period = "28"
    @State private var metricIndex = 0
    @State private var settings = false
    @State private var newVideo = false
    @State private var newComment = false
    @State private var editVideo: Video?
    @State private var editComment: Comment?
    @State private var editMetric: Metric?
    @State private var showNotes = false
    @State private var search = ""
    @State private var kind = "All"
    @State private var unanswered = false
    var metrics: [Metric] { store.data.metrics[period] ?? [] }
    var body: some View {
        TabView(selection: $tab) {
            page("Dashboard") { dashboard }.tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }.tag(0)
            page("Content") { content }.tabItem { Label("Content", systemImage: "play.rectangle") }.tag(1)
            page("Analytics") { analytics }.tabItem { Label("Analytics", systemImage: "chart.bar.xaxis") }.tag(2)
            page("Community") { community }.tabItem { Label("Community", systemImage: "person.2") }.tag(3)
            page("Earn") { earn }.tabItem { Label("Earn", systemImage: "dollarsign.circle") }.tag(4)
        }
        .sheet(isPresented: $settings) { HubSettings(store: store) }
        .sheet(isPresented: $newVideo) { VideoEditor(store: store, draft: Video()) }
        .sheet(item: $editVideo) { VideoEditor(store: store, draft: $0) }
        .sheet(isPresented: $newComment) { CommentEditor(store: store, draft: Comment()) }
        .sheet(item: $editComment) { CommentEditor(store: store, draft: $0) }
        .sheet(item: $editMetric) { metric in MetricEditor(store: store, period: period, draft: metric) }
        .sheet(isPresented: $showNotes) {
            NavigationStack {
                List {
                    Label("Your workspace is saved on this iPhone.", systemImage: "internaldrive")
                    Label("Metrics and earnings are personal sample data.", systemImage: "chart.bar")
                    Label("Use Settings to export a backup.", systemImage: "square.and.arrow.up")
                }.navigationTitle("Activity").toolbar { Button("Done") { showNotes = false } }
            }
        }.errorAlert($store.error)
    }
    func page<Content: View>(_ title: String, @ViewBuilder view: () -> Content) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) { view() }.padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .refreshable { store.save() }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 5) { Image(systemName: "chart.bar.fill").foregroundStyle(.red); Text("Smore Hub").font(.headline) }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu { Button("Add content", systemImage: "play.rectangle") { newVideo = true }; Button("Add sample comment", systemImage: "text.bubble") { newComment = true } } label: { Image(systemName: "plus.circle") }.accessibilityLabel("Create")
                    Button { showNotes = true } label: { Image(systemName: "bell") }.accessibilityLabel("Activity")
                    Button { settings = true } label: { LocalImage(data: store.data.avatar).frame(width: 28,height: 28).clipShape(Circle()) }.accessibilityLabel("Profile and settings")
                }
            }
        }
    }
    var rangePicker: some View {
        Picker("Date range", selection: $period) {
            Text("7 days").tag("7"); Text("28 days").tag("28"); Text("90 days").tag("90"); Text("1 year").tag("365")
        }.pickerStyle(.segmented)
    }
    var dashboard: some View {
        Group {
            HStack(spacing: 18) {
                Button { settings = true } label: { LocalImage(data: store.data.avatar).frame(width: 72, height: 72).clipShape(Circle()) }.accessibilityLabel("Edit channel")
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.data.channel).font(.title2.bold())
                    Text(store.data.subscribers.formatted()).font(.largeTitle.bold())
                    Text("Total subscribers").foregroundStyle(.secondary)
                }
            }.padding(.vertical, 8)
            Label("Personal simulation · Editable sample data", systemImage: "pencil.circle").font(.caption).foregroundStyle(.secondary)
            Text("Channel analytics").font(.title2.bold())
            rangePicker
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                    Button { editMetric = metric } label: { metricCard(metric, index: index) }.buttonStyle(.plain)
                }
            }
            Button { tab = 2 } label: { Label("Explore analytics", systemImage: "chart.xyaxis.line") }
            Text("Latest published content").font(.title2.bold())
            if store.data.videos.isEmpty { empty("No content yet", "Add your first local content entry with +.") }
            ForEach(store.data.videos.prefix(5)) { video in videoCard(video) }
        }
    }
    func metricCard(_ metric: Metric, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(metric.title).font(.subheadline.weight(.medium)).foregroundStyle(.secondary).lineLimit(2)
            HStack(spacing: 6) {
                Text(index == 3 ? store.data.currency + compact(metric.value) : (index == 2 ? "+" : "") + compact(metric.value)).font(.title2.bold()).minimumScaleFactor(0.5).lineLimit(1)
                status(metric.status, revenue: index == 3)
            }
        }.frame(maxWidth: .infinity, minHeight: 78, alignment: .leading).card()
            .accessibilityElement(children: .combine).accessibilityHint("Edit value and status")
    }
    func status(_ status: MetricStatus, revenue: Bool) -> some View {
        let effective: MetricStatus = status == .automatic ? (revenue ? .check : .down) : status
        return Image(systemName: effective.symbol).foregroundStyle(effective == .warning ? Color.orange : effective == .down ? Color.secondary : Color.green).font(.subheadline)
    }
    func videoCard(_ video: Video) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button { editVideo = video } label: {
                HStack(spacing: 14) {
                    LocalImage(data: video.thumbnail, symbol: "play.rectangle.fill").frame(width: 56,height: 76).clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(video.title).font(.headline).lineLimit(2)
                        Text(video.age).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }.buttonStyle(.plain)
            Divider()
            HStack(spacing: 22) {
                Label(compact(video.views), systemImage: "chart.bar")
                Label(compact(Double(video.likes)), systemImage: "hand.thumbsup")
                Label(compact(Double(video.commentCount)), systemImage: "text.bubble")
            }.font(.subheadline.bold())
            DisclosureGroup("Comments · \(video.commentCount)") {
                VStack(alignment: .leading, spacing: 10) {
                    if let comment = store.data.comments.first {
                        Button { editComment = comment } label: { Text("\(comment.author) · \(comment.age)\n\(comment.text)").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(.plain)
                    }
                    Button("Open community") { tab = 3 }
                }.padding(.top, 10)
            }.font(.subheadline)
        }.card()
    }
    var content: some View {
        Group {
            TextField("Search titles", text: $search).textFieldStyle(.roundedBorder).accessibilityLabel("Search content")
            Picker("Type", selection: $kind) { ForEach(["All","Short","Video","Live","Post"], id: \.self) { Text($0).tag($0) } }.pickerStyle(.segmented)
            let filtered = store.data.videos.filter { (kind == "All" || $0.kind == kind) && (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search)) }
            if filtered.isEmpty { empty("No matching content", "Try another search or add an entry.") }
            ForEach(filtered) { video in videoCard(video) }
            Button("Add local content entry", systemImage: "plus") { newVideo = true }.buttonStyle(.borderedProminent)
            Text("Entries stay on your phone. This workspace does not publish videos or connect to YouTube.").font(.footnote).foregroundStyle(.secondary)
        }
    }
    var analytics: some View {
        Group {
            rangePicker
            Picker("Metric", selection: $metricIndex) {
                Text("Views").tag(0); Text("Hours").tag(1); Text("Subs").tag(2); Text("Revenue").tag(3)
            }.pickerStyle(.segmented)
            if metrics.indices.contains(metricIndex) {
                let metric = metrics[metricIndex]
                Button { editMetric = metric } label: { metricCard(metric, index: metricIndex) }.buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Illustrative distribution").font(.headline)
                    Chart(Array(0..<14), id: \.self) { day in
                        let weight = Double((day * 7 + 3) % 11 + 3)
                        BarMark(x: .value("Day", day+1), y: .value(metric.title, metric.value * weight / 116))
                            .foregroundStyle(Color.red.gradient).cornerRadius(3)
                    }.frame(height: 190).accessibilityLabel("Illustrative chart derived from the editable total")
                    Text("Generated from your total for visualization; these are not measured daily statistics.").font(.caption).foregroundStyle(.secondary)
                }.card()
            }
            Text("Top content").font(.title2.bold())
            ForEach(store.data.videos.sorted { $0.views > $1.views }) { video in
                Button { editVideo = video } label: {
                    HStack { Text(video.title).lineLimit(1); Spacer(); Text(compact(video.views)).bold() }.card()
                }.buttonStyle(.plain)
            }
        }
    }
    var community: some View {
        Group {
            Toggle("Unanswered only", isOn: $unanswered)
            let filtered = store.data.comments.filter { !unanswered || $0.reply.isEmpty }
            if filtered.isEmpty { empty("All caught up", "Add a sample comment or turn off the filter.") }
            ForEach(filtered) { comment in
                VStack(alignment: .leading, spacing: 12) {
                    Button { editComment = comment } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(comment.author) · \(comment.age)").font(.subheadline.bold())
                            Text(comment.text)
                            if !comment.reply.isEmpty { Text("Your reply: \(comment.reply)").foregroundStyle(.secondary) }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.buttonStyle(.plain)
                    HStack {
                        Button {
                            if let i = store.data.comments.firstIndex(where: { $0.id == comment.id }) { store.data.comments[i].hearted.toggle() }
                        } label: { Label(comment.hearted ? "Hearted" : "Heart", systemImage: comment.hearted ? "heart.fill" : "heart") }
                        Spacer()
                        Button("Edit / reply") { editComment = comment }
                    }.font(.subheadline)
                }.card()
            }
            Button("Add sample comment", systemImage: "plus.bubble") { newComment = true }
        }
    }
    var earn: some View {
        let revenue = (store.data.metrics[period] ?? []).last?.value ?? 0
        return Group {
            rangePicker
            VStack(alignment: .leading, spacing: 12) {
                Text("Estimated revenue").foregroundStyle(.secondary)
                Text(store.data.currency + revenue.formatted(.number.precision(.fractionLength(2)))).font(.largeTitle.bold())
                Text("Personal sample · No real payout").font(.caption).foregroundStyle(.secondary)
                ProgressView(value: min(1, revenue/store.data.payoutGoal))
                Text("\(store.data.currency)\(store.data.payoutGoal.formatted()) goal").font(.subheadline)
                Button("Edit revenue") { if let metric = metrics.last { editMetric = metric } }
            }.card()
            Text("Build your next milestone").font(.title2.bold())
            Label("Create consistently", systemImage: "calendar").card()
            Label("Listen to your community", systemImage: "person.2").card()
            Button("Edit payout goal and profile") { settings = true }
        }
    }
    func empty(_ title: String, _ text: String) -> some View {
        ContentUnavailableView(title, systemImage: "tray", description: Text(text))
    }
}

struct HubSettings: View {
    @ObservedObject var store: DiskStore<HubData>
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Channel") {
                    LocalImage(data: store.data.avatar).frame(width: 80,height: 80).clipShape(Circle())
                    PhotoControl(data: $store.data.avatar, label: "Choose channel avatar")
                    if store.data.avatar != nil { Button("Remove avatar", role: .destructive) { store.data.avatar = nil } }
                    TextField("Channel name", text: $store.data.channel)
                    HStack { Text("Subscribers"); TextField("Subscribers", value: $store.data.subscribers, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                    TextField("Currency", text: $store.data.currency)
                    HStack { Text("Payout goal"); TextField("Payout goal", value: $store.data.payoutGoal, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                }
                Section("Appearance") {
                    Picker("Theme", selection: $store.data.appearance) { Text("Device").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark") }
                    Text("The avatar changes inside the app. The Home Screen icon is fixed at build time.").font(.footnote)
                }
                Section("Backup") { BackupControls(store: store, filename: "SmoreHub-backup") }
                Section("About") { Text("A private, offline creator dashboard. All metrics, comments, and earnings are editable sample data. No Google account, uploads, live streams, analytics collection, or revenue payments.").font(.footnote) }
            }.navigationTitle("Profile & settings").toolbar { Button("Done") { dismiss() } }
        }
    }
}
struct MetricEditor: View {
    @ObservedObject var store: DiskStore<HubData>
    var period: String
    @State var draft: Metric
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("\(period)-day range") {
                    TextField("Value", value: $draft.value, format: .number).keyboardType(.decimalPad)
                    Picker("Status icon", selection: $draft.status) { ForEach(MetricStatus.allCases) { Text($0.rawValue.capitalized).tag($0) } }
                    Text("Automatic uses down for activity and a green check for revenue. Values are yours to enter.").font(.footnote)
                }
            }.navigationTitle(draft.title).toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") {
                    guard draft.value.isFinite, draft.value >= 0 else { error = "Use a nonnegative number."; return }
                    if let i = store.data.metrics[period]?.firstIndex(where: { $0.id == draft.id }) { store.data.metrics[period]?[i] = draft }
                    dismiss()
                } }
            }.errorAlert($error)
        }
    }
}
struct VideoEditor: View {
    @ObservedObject var store: DiskStore<HubData>
    @State var draft: Video
    @State private var error: String?
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $draft.title, axis: .vertical)
                Picker("Type", selection: $draft.kind) { ForEach(["Short","Video","Live","Post"], id: \.self) { Text($0).tag($0) } }
                TextField("Age label", text: $draft.age)
                TextField("Views", value: $draft.views, format: .number).keyboardType(.decimalPad)
                TextField("Likes", value: $draft.likes, format: .number).keyboardType(.numberPad)
                TextField("Comment count", value: $draft.commentCount, format: .number).keyboardType(.numberPad)
                PhotoControl(data: $draft.thumbnail, label: "Choose thumbnail")
                if draft.thumbnail != nil {
                    LocalImage(data: draft.thumbnail).frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 12))
                    Button("Remove thumbnail", role: .destructive) { draft.thumbnail = nil }
                }
                if store.data.videos.contains(where: { $0.id == draft.id }) { Button("Delete content", role: .destructive) { deleting = true } }
            }.navigationTitle("Content details").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") {
                    do {
                        var candidate = store.data
                        if let i = candidate.videos.firstIndex(where: { $0.id == draft.id }) { candidate.videos[i] = draft } else { candidate.videos.insert(draft, at: 0) }
                        try candidate.validate(); store.data = candidate; dismiss()
                    } catch { self.error = error.localizedDescription }
                } }
            }.confirmationDialog("Delete this content entry?", isPresented: $deleting) {
                Button("Delete", role: .destructive) { store.data.videos.removeAll { $0.id == draft.id }; dismiss() }
            }.errorAlert($error)
        }
    }
}
struct CommentEditor: View {
    @ObservedObject var store: DiskStore<HubData>
    @State var draft: Comment
    @State private var deleting = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $draft.author)
                TextField("Time label", text: $draft.age)
                TextField("Comment", text: $draft.text, axis: .vertical)
                TextField("Your reply", text: $draft.reply, axis: .vertical)
                Toggle("Hearted", isOn: $draft.hearted)
                if store.data.comments.contains(where: { $0.id == draft.id }) { Button("Delete comment", role: .destructive) { deleting = true } }
            }.navigationTitle("Sample comment").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") {
                    do {
                        var candidate = store.data
                        if let i = candidate.comments.firstIndex(where: { $0.id == draft.id }) { candidate.comments[i] = draft } else { candidate.comments.insert(draft, at: 0) }
                        try candidate.validate(); store.data = candidate; dismiss()
                    } catch { self.error = error.localizedDescription }
                } }
            }.confirmationDialog("Delete this comment?", isPresented: $deleting) { Button("Delete", role: .destructive) { store.data.comments.removeAll { $0.id == draft.id }; dismiss() } }
            .errorAlert($error)
        }
    }
}
