import Foundation
import Combine

class ExperimentStore: ObservableObject {
    @Published var myExperiments: [Experiment] = []
    @Published var communityExperiments: [Experiment] = []

    private let saveKey = "cosmos_experiments"

    init() {
        load()
        seedCommunityIfNeeded()
    }

    // MARK: - CRUD

    func add(_ experiment: Experiment) {
        myExperiments.append(experiment)
        save()
    }

    func checkIn(experimentId: UUID, note: String?) {
        guard let i = myExperiments.firstIndex(where: { $0.id == experimentId }) else { return }
        let entry = CheckIn(date: Date(), didComplete: true, note: note)
        myExperiments[i].checkIns.append(entry)
        save()
    }

    func close(experimentId: UUID, as status: ExperimentStatus, reflection: String?) {
        guard let i = myExperiments.firstIndex(where: { $0.id == experimentId }) else { return }
        myExperiments[i].status = status
        myExperiments[i].endDate = Date()
        myExperiments[i].closingReflection = reflection
        save()
    }

    func orbitCommunityExperiment(_ experiment: Experiment) {
        var copy = experiment
        copy.id = UUID()
        copy.startDate = Date()
        copy.checkIns = []
        copy.status = .active
        myExperiments.append(copy)
        save()
    }

    var activeExperiments: [Experiment] {
        myExperiments.filter { $0.status == .active }
    }

    var closedExperiments: [Experiment] {
        myExperiments.filter { $0.status != .active }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(myExperiments) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode([Experiment].self, from: data) else { return }
        myExperiments = saved
    }

    // MARK: - Community Seed Data

    private func seedCommunityIfNeeded() {
        communityExperiments = [
            Experiment(name: "Wake before 5am", intention: "See what the quiet hours feel like before the world starts.", frequency: .daily, durationDays: 30, startDate: Date().addingTimeInterval(-864000), status: .active, isPublic: true, planetAsset: "planet_01", checkIns: mockCheckIns(count: 10)),
            Experiment(name: "No phone first hour", intention: "Reclaim my mornings as my own.", frequency: .daily, durationDays: 21, startDate: Date().addingTimeInterval(-604800), status: .active, isPublic: true, planetAsset: "planet_04", checkIns: mockCheckIns(count: 6)),
            Experiment(name: "Write 200 words a day", intention: "Build the muscle of showing up on the page.", frequency: .daily, durationDays: nil, startDate: Date().addingTimeInterval(-1296000), status: .active, isPublic: true, planetAsset: "planet_07", checkIns: mockCheckIns(count: 15)),
            Experiment(name: "Cold shower every morning", intention: "Test if the hype is real for me.", frequency: .daily, durationDays: 14, startDate: Date().addingTimeInterval(-432000), status: .active, isPublic: true, planetAsset: "planet_06", checkIns: mockCheckIns(count: 4)),
            Experiment(name: "No alcohol for a month", intention: "Curious what sleep actually feels like.", frequency: .weekly, durationDays: 30, startDate: Date().addingTimeInterval(-1728000), status: .active, isPublic: true, planetAsset: "planet_03", checkIns: mockCheckIns(count: 3)),
            Experiment(name: "Walk without headphones", intention: "Let my mind wander without filling the silence.", frequency: .severalTimesWeek, durationDays: nil, startDate: Date().addingTimeInterval(-259200), status: .active, isPublic: true, planetAsset: "planet_10", checkIns: mockCheckIns(count: 2)),
            Experiment(name: "One meal a day", intention: "Explore intermittent fasting properly.", frequency: .daily, durationDays: 7, startDate: Date().addingTimeInterval(-172800), status: .active, isPublic: true, planetAsset: "planet_02", checkIns: mockCheckIns(count: 2)),
            Experiment(name: "Read fiction before bed", intention: "Replace doom scrolling with something that fills me.", frequency: .daily, durationDays: nil, startDate: Date().addingTimeInterval(-518400), status: .active, isPublic: true, planetAsset: "planet_11", checkIns: mockCheckIns(count: 5)),
        ]
    }

    private func mockCheckIns(count: Int) -> [CheckIn] {
        (0..<count).map { i in
            CheckIn(date: Date().addingTimeInterval(Double(-i) * 86400), didComplete: true, note: nil)
        }
    }
}
