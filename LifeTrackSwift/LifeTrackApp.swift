import SwiftUI

@main
struct LifeTrackApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct SleepEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: Double
    let result: String

    init(date: Date = .now, duration: Double, result: String) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.result = result
    }
}

struct WorkoutEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: String
    let duration: Int
    let notes: String
}

struct Habit: Identifiable {
    let id: Int
    let title: String
    var completed = false
}

@MainActor
final class LifeTrackStore: ObservableObject {
    @Published var sleepLog: [SleepEntry] = []
    @Published var workoutLog: [WorkoutEntry] = []
    @Published var habits: [Habit] = [
        Habit(id: 1, title: "Drank 1 gallon of water"),
        Habit(id: 2, title: "Hit protein goal"),
        Habit(id: 3, title: "Worked out"),
        Habit(id: 4, title: "Read 10 pages"),
        Habit(id: 5, title: "Outside walk / 45 min cardio"),
        Habit(id: 6, title: "No alcohol"),
        Habit(id: 7, title: "Morning scripture / prayer"),
        Habit(id: 8, title: "Followed meal prep plan")
    ]

    private let defaults = UserDefaults.standard
    private let sleepKey = "lifetrack.sleepLog"
    private let workoutKey = "lifetrack.workoutLog"
    private let habitsKey = "lifetrack.habits"

    init() {
        load()
    }

    func saveSleep(duration: Double, result: String) {
        sleepLog.insert(SleepEntry(duration: duration, result: result), at: 0)
        sleepLog = Array(sleepLog.prefix(20))
        persist(sleepLog, key: sleepKey)
    }

    func saveWorkout(type: String, duration: Int, notes: String) {
        workoutLog.insert(WorkoutEntry(id: UUID(), date: .now, type: type, duration: duration, notes: notes), at: 0)
        workoutLog = Array(workoutLog.prefix(20))
        persist(workoutLog, key: workoutKey)
    }

    func saveHabits() {
        defaults.set(habits.map(\.completed), forKey: habitsKey)
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = defaults.data(forKey: sleepKey),
           let value = try? JSONDecoder().decode([SleepEntry].self, from: data) {
            sleepLog = value
        }
        if let data = defaults.data(forKey: workoutKey),
           let value = try? JSONDecoder().decode([WorkoutEntry].self, from: data) {
            workoutLog = value
        }
        if let saved = defaults.array(forKey: habitsKey) as? [Bool], saved.count == habits.count {
            for index in habits.indices {
                habits[index].completed = saved[index]
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var store = LifeTrackStore()
    @State private var selectedTab: Tab = .sleep

    enum Tab: String, CaseIterable {
        case sleep = "Sleep"
        case gym = "Gym"
        case habits = "Habits"
        case summary = "Summary"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 4) {
                        Text("LifeTrack")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                        Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)

                    Picker("Section", selection: $selectedTab) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    Group {
                        switch selectedTab {
                        case .sleep: SleepView(store: store)
                        case .gym: GymView(store: store)
                        case .habits: HabitsView(store: store)
                        case .summary: SummaryView(store: store)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
        }
    }
}

struct SleepView: View {
    @ObservedObject var store: LifeTrackStore
    @State private var bedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: .now) ?? .now
    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now
    @State private var result: String?

    var body: some View {
        SectionView(title: "Sleep Tracker") {
            DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
            DatePicker("Wake Up", selection: $wakeTime, displayedComponents: .hourAndMinute)
            PrimaryButton(title: "Log Sleep") { logSleep() }
            if let result { ResultText(result) }
        }
        if !store.sleepLog.isEmpty {
            HistoryView(title: "Recent Sleep", items: store.sleepLog.prefix(5).map { entry in
                "\(entry.date.formatted(date: .omitted, time: .shortened)) — \(entry.result)"
            })
        }
    }

    private func logSleep() {
        var duration = wakeTime.timeIntervalSince(bedtime) / 3600
        if duration < 0 { duration += 24 }
        let hours = Int(duration)
        let minutes = Int(((duration - Double(hours)) * 60).rounded())
        let quality = duration >= 8 ? "Great" : duration >= 7 ? "Good" : duration >= 6 ? "Okay" : "Poor"
        let text = "\(hours)h \(minutes)m — \(quality) sleep"
        result = text
        store.saveSleep(duration: duration, result: text)
    }
}

struct GymView: View {
    @ObservedObject var store: LifeTrackStore
    private let workoutTypes = ["Push (Chest/Shoulders/Tris)", "Pull (Back/Bis)", "Legs", "Cardio", "Full Body"]
    @State private var type = "Push (Chest/Shoulders/Tris)"
    @State private var duration = ""
    @State private var notes = ""
    @State private var showingError = false

    var body: some View {
        SectionView(title: "Gym Tracker") {
            Picker("Workout Type", selection: $type) {
                ForEach(workoutTypes, id: \.self, content: Text.init)
            }
            TextField("Duration (minutes)", text: $duration)
                .keyboardType(.numberPad)
            TextField("Notes", text: $notes)
            PrimaryButton(title: "Log Workout") { logWorkout() }
                .alert("Enter a workout duration first.", isPresented: $showingError) {
                    Button("OK", role: .cancel) { }
                }
        }
        if !store.workoutLog.isEmpty {
            HistoryView(title: "Recent Workouts", items: store.workoutLog.prefix(5).map { entry in
                "\(entry.date.formatted(date: .omitted, time: .shortened)) — \(entry.type) (\(entry.duration) min)\(entry.notes.isEmpty ? "" : " · \(entry.notes)")"
            })
        }
    }

    private func logWorkout() {
        guard let minutes = Int(duration), minutes > 0 else {
            showingError = true
            return
        }
        store.saveWorkout(type: type, duration: minutes, notes: notes)
        duration = ""
        notes = ""
    }
}

struct HabitsView: View {
    @ObservedObject var store: LifeTrackStore
    @State private var savedMessage = false

    var body: some View {
        SectionView(title: "Daily Habits") {
            ForEach(store.habits.indices, id: \.self) { index in
                Toggle(store.habits[index].title, isOn: $store.habits[index].completed)
                    .tint(.green)
            }
            PrimaryButton(title: "Save Habits") {
                store.saveHabits()
                savedMessage = true
            }
            if savedMessage {
                ResultText("\(completedCount)/\(store.habits.count) habits completed (\(percentage)%)")
            }
        }
    }

    private var completedCount: Int { store.habits.filter(\.completed).count }
    private var percentage: Int { Int((Double(completedCount) / Double(store.habits.count) * 100).rounded()) }
}

struct SummaryView: View {
    @ObservedObject var store: LifeTrackStore
    private var latestSleep: SleepEntry? { store.sleepLog.first }
    private var latestWorkout: WorkoutEntry? { store.workoutLog.first }
    private var completedHabits: Int { store.habits.filter(\.completed).count }
    private var score: Int {
        var value = 0
        if let sleep = latestSleep, sleep.duration >= 7 { value += 34 }
        if latestWorkout != nil { value += 33 }
        value += Int((Double(completedHabits) / Double(store.habits.count) * 33).rounded())
        return value
    }

    var body: some View {
        SectionView(title: "Today's Summary") {
            LazyVGrid(columns: [GridItem(), GridItem()], spacing: 12) {
                SummaryBox(label: "Sleep", value: latestSleep.map { String(format: "%.1fh", $0.duration) } ?? "--")
                SummaryBox(label: "Workout", value: latestWorkout?.type ?? "Rest")
                SummaryBox(label: "Habits", value: "\(completedHabits)/\(store.habits.count)")
                SummaryBox(label: "Day Score", value: score == 0 ? "--" : "\(score)%")
            }
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title3.bold())
            VStack(alignment: .leading, spacing: 14, content: { content })
                .padding(18)
                .background(Color(white: 0.10), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Text(title).frame(maxWidth: .infinity) }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .foregroundStyle(.black)
    }
}

struct ResultText: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct HistoryView: View {
    let title: String
    let items: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    Text(item).font(.footnote).foregroundStyle(.secondary).padding(.vertical, 9)
                    Divider()
                }
            }
            .padding(.horizontal, 14)
            .background(Color(white: 0.10), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct SummaryBox: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 8) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.bold()).foregroundStyle(.green).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .padding(8)
        .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 12))
    }
}
