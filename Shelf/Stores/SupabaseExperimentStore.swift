import Foundation
import Combine
import UIKit

// MARK: - Enhanced Experiment Store with Supabase Integration
// Maintains existing COSMOS interface while adding cloud sync + social features

@MainActor
class SupabaseExperimentStore: ObservableObject {
    @Published var myExperiments: [Experiment] = []
    @Published var communityExperiments: [Experiment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService: SupabaseService
    private let localStore: LocalExperimentStore
    private var cancellables = Set<AnyCancellable>()
    
    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
        self.localStore = LocalExperimentStore()
        
        // Start with local data for immediate UI
        self.myExperiments = localStore.experiments
        
        // Listen for auth changes
        supabaseService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    Task { await self?.syncWithServer() }
                } else {
                    self?.myExperiments = self?.localStore.experiments ?? []
                }
            }
            .store(in: &cancellables)
        
        // Initial load
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Computed Properties (maintains COSMOS interface)
    
    var activeExperiments: [Experiment] {
        myExperiments.filter { $0.status == .active }
    }
    
    var closedExperiments: [Experiment] {
        myExperiments.filter { $0.status != .active }
    }
    
    // MARK: - CRUD Operations (enhanced with cloud sync)
    
    func add(_ experiment: Experiment) {
        // Add locally first for immediate UI feedback
        localStore.add(experiment)
        myExperiments = localStore.experiments
        
        // Sync to cloud if authenticated
        if supabaseService.isAuthenticated {
            Task {
                do {
                    let _ = try await supabaseService.createExperiment(ExperimentData(from: experiment))
                    await syncWithServer() // Refresh from server
                } catch {
                    handleError(error)
                }
            }
        }
    }
    
    func checkIn(experimentId: UUID, on date: Date = Date(), note: String?) {
        localStore.checkIn(experimentId: experimentId, on: date, note: note)
        myExperiments = localStore.experiments

        if supabaseService.isAuthenticated {
            Task {
                do {
                    let _ = try await supabaseService.addCheckIn(experimentId: experimentId, note: note)
                    // If a target experiment just auto-completed, sync the status change
                    if let exp = myExperiments.first(where: { $0.id == experimentId }),
                       exp.status == .completed,
                       exp.experimentType == .target {
                        let _ = try await supabaseService.updateExperiment(ExperimentData(from: exp))
                    }
                } catch {
                    handleError(error)
                }
            }
        }
    }

    func removeCheckIn(experimentId: UUID, on date: Date) {
        localStore.removeCheckIn(experimentId: experimentId, on: date)
        myExperiments = localStore.experiments
    }

    func addObservation(experimentId: UUID, note: String) {
        localStore.checkIn(experimentId: experimentId, note: note)
        myExperiments = localStore.experiments
        // Mark as observation (didComplete: false)
        if let i = myExperiments.firstIndex(where: { $0.id == experimentId }),
           !myExperiments[i].checkIns.isEmpty {
            let last = myExperiments[i].checkIns.count - 1
            myExperiments[i].checkIns[last] = CheckIn(date: Date(), didComplete: false, note: note)
            localStore.replaceAll(myExperiments)
        }

        if supabaseService.isAuthenticated {
            Task {
                do {
                    let _ = try await supabaseService.addCheckIn(experimentId: experimentId, note: note)
                } catch {
                    handleError(error)
                }
            }
        }
    }

    func close(experimentId: UUID, as status: ExperimentStatus, reflection: String?) {
        // Update locally first
        localStore.close(experimentId: experimentId, as: status, reflection: reflection)
        myExperiments = localStore.experiments
        
        // Sync to cloud
        if supabaseService.isAuthenticated {
            Task {
                do {
                    if let experiment = myExperiments.first(where: { $0.id == experimentId }) {
                        let _ = try await supabaseService.updateExperiment(ExperimentData(from: experiment))
                    }
                } catch {
                    handleError(error)
                }
            }
        }
    }
    
    func delete(experimentId: UUID) {
        // Delete locally first
        localStore.delete(experimentId: experimentId)
        myExperiments = localStore.experiments
        
        // Delete from cloud
        if supabaseService.isAuthenticated {
            Task {
                do {
                    try await supabaseService.deleteExperiment(experimentId)
                } catch {
                    handleError(error)
                }
            }
        }
    }
    
    // MARK: - Social Features (NEW)
    
    func orbitCommunityExperiment(_ experiment: Experiment) {
        var copy = experiment
        copy.id = UUID()
        copy.startDate = Date()
        copy.checkIns = []
        copy.status = .active
        
        add(copy)
    }
    
    func likeExperiment(_ experiment: Experiment) {
        guard supabaseService.isAuthenticated else { return }
        
        Task {
            do {
                try await supabaseService.likeExperiment(experiment.id)
            } catch {
                handleError(error)
            }
        }
    }
    
    func loadCommunityExperiments() {
        guard supabaseService.isAuthenticated else {
            // Use seed data when offline
            communityExperiments = createSeedCommunityExperiments()
            return
        }
        
        Task {
            isLoading = true
            do {
                let experiments = try await supabaseService.getPublicExperiments(limit: 50)
                communityExperiments = experiments.map { convertToExperiment($0) }
            } catch {
                handleError(error)
                // Fallback to seed data
                communityExperiments = createSeedCommunityExperiments()
            }
            isLoading = false
        }
    }
    
    // MARK: - Image Management (ENHANCED)
    
    func saveCustomImage(_ image: UIImage, for experimentId: UUID) {
        // Save locally first
        localStore.saveCustomImage(image, for: experimentId)
        
        // Update experiment to mark as having custom image
        if let index = myExperiments.firstIndex(where: { $0.id == experimentId }) {
            myExperiments[index].hasCustomImage = true
        }
        
        // Upload to cloud storage if authenticated
        if supabaseService.isAuthenticated {
            Task {
                do {
                    // Process image: background removal + compression
                    let processedImage = await BackgroundRemover.process(image)
                    guard let imageData = processedImage.jpegData(compressionQuality: 0.8) else { return }
                    
                    let imageUrl = try await supabaseService.uploadExperimentImage(imageData, experimentId: experimentId)
                    
                    // Update experiment with image URL
                    if let experiment = myExperiments.first(where: { $0.id == experimentId }) {
                        var updatedData = ExperimentData(from: experiment)
                        updatedData.customImageUrl = imageUrl
                        updatedData.hasCustomImage = true
                        let _ = try await supabaseService.updateExperiment(updatedData)
                    }
                } catch {
                    handleError(error)
                }
            }
        }
    }
    
    func loadCustomImage(for experimentId: UUID) -> UIImage? {
        return localStore.loadCustomImage(for: experimentId)
    }
    
    // MARK: - Sync Logic
    
    private func loadInitialData() async {
        if supabaseService.isAuthenticated {
            await syncWithServer()
        } else {
            // Load local data
            myExperiments = localStore.experiments
        }
        
        // Always load community experiments
        loadCommunityExperiments()
    }
    
    private func syncWithServer() async {
        guard supabaseService.isAuthenticated else { return }
        
        isLoading = true
        do {
            // Fetch user experiments from server
            let serverExperiments = try await supabaseService.getUserExperiments()
            let convertedExperiments = serverExperiments.map { convertToExperiment($0) }
            
            // Merge with local experiments (server wins for conflicts)
            myExperiments = mergeExperiments(local: localStore.experiments, server: convertedExperiments)
            
            // Update local storage with merged result
            localStore.replaceAll(myExperiments)
            
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    // MARK: - Data Conversion
    
    private func convertToExperiment(_ data: ExperimentData) -> Experiment {
        return Experiment(
            id: data.id,
            name: data.name,
            intention: data.intention,
            experimentType: ExperimentType(rawValue: data.experimentType) ?? .habit,
            frequency: CheckInFrequency(rawValue: data.frequency ?? "Daily"),
            timesPerWeek: data.timesPerWeek,
            targetCount: data.targetCount,
            durationDays: data.durationDays,
            startDate: data.startDate,
            endDate: data.endDate,
            status: ExperimentStatus(rawValue: data.status) ?? .active,
            isPublic: data.isPublic,
            iconPreset: ExperimentIcon(rawValue: data.iconPreset) ?? .book,
            hasCustomImage: data.hasCustomImage,
            checkIns: data.checkIns?.map { convertToCheckIn($0) } ?? [],
            closingReflection: data.closingReflection
        )
    }
    
    private func convertToCheckIn(_ data: CheckInData) -> CheckIn {
        return CheckIn(
            id: data.id ?? UUID(),
            date: data.date,
            didComplete: data.didComplete,
            note: data.note
        )
    }
    
    private func mergeExperiments(local: [Experiment], server: [Experiment]) -> [Experiment] {
        var merged: [UUID: Experiment] = [:]
        
        // Add all local experiments
        for experiment in local {
            merged[experiment.id] = experiment
        }
        
        // Server experiments override local (server is source of truth)
        for experiment in server {
            merged[experiment.id] = experiment
        }
        
        return Array(merged.values).sorted { $0.startDate > $1.startDate }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        print("ExperimentStore Error: \(error)")
        errorMessage = error.localizedDescription
        
        // Clear error after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.errorMessage = nil
        }
    }
    
    // MARK: - Seed Data (fallback for offline)
    
    private func createSeedCommunityExperiments() -> [Experiment] {
        return [
            Experiment(name: "Wake before 5am", intention: "See what the quiet hours feel like before the world starts.", frequency: .daily, durationDays: 30, startDate: Date().addingTimeInterval(-864000), status: .active, isPublic: true, iconPreset: .mug, checkIns: mockCheckIns(count: 10)),
            Experiment(name: "No phone first hour", intention: "Reclaim my mornings as my own.", frequency: .daily, durationDays: 21, startDate: Date().addingTimeInterval(-604800), status: .active, isPublic: true, iconPreset: .book, checkIns: mockCheckIns(count: 6)),
            Experiment(name: "Write 200 words a day", intention: "Build the muscle of showing up on the page.", frequency: .daily, startDate: Date().addingTimeInterval(-1296000), status: .active, isPublic: true, iconPreset: .brush, checkIns: mockCheckIns(count: 15)),
            Experiment(name: "Cold shower every morning", intention: "Test if the hype is real for me.", frequency: .daily, durationDays: 14, startDate: Date().addingTimeInterval(-432000), status: .active, isPublic: true, iconPreset: .run, checkIns: mockCheckIns(count: 4)),
            Experiment(name: "No alcohol for a month", intention: "Curious what sleep actually feels like.", frequency: .weekly, durationDays: 30, startDate: Date().addingTimeInterval(-1728000), status: .active, isPublic: true, iconPreset: .cook, checkIns: mockCheckIns(count: 3)),
            Experiment(name: "Walk without headphones", intention: "Let my mind wander without filling the silence.", frequency: .severalTimesWeek, startDate: Date().addingTimeInterval(-259200), status: .active, isPublic: true, iconPreset: .headphones, checkIns: mockCheckIns(count: 2)),
            Experiment(name: "Read fiction before bed", intention: "Replace doom scrolling with something that fills me.", frequency: .daily, startDate: Date().addingTimeInterval(-518400), status: .active, isPublic: true, iconPreset: .book, checkIns: mockCheckIns(count: 5)),
            Experiment(name: "30 min weights daily", intention: "Stop starting and stopping. Just show up.", frequency: .daily, durationDays: 30, startDate: Date().addingTimeInterval(-172800), status: .active, isPublic: true, iconPreset: .weights, checkIns: mockCheckIns(count: 2)),
        ]
    }
    
    private func mockCheckIns(count: Int) -> [CheckIn] {
        (0..<count).map { i in
            CheckIn(date: Date().addingTimeInterval(Double(-i) * 86400), didComplete: true, note: nil)
        }
    }
}

// MARK: - Local Store (maintains offline functionality)

class LocalExperimentStore {
    private let saveKey = "cosmos_experiments"
    var experiments: [Experiment] = []
    
    init() {
        load()
    }
    
    func add(_ experiment: Experiment) {
        experiments.append(experiment)
        save()
    }
    
    func checkIn(experimentId: UUID, on date: Date = Date(), note: String?) {
        guard let i = experiments.firstIndex(where: { $0.id == experimentId }) else { return }
        let cal = Calendar(identifier: .iso8601)
        // Prevent duplicate check-ins on the same calendar day
        guard !experiments[i].checkIns.contains(where: { $0.didComplete && cal.isDate($0.date, inSameDayAs: date) }) else { return }
        let entry = CheckIn(date: date, didComplete: true, note: note)
        experiments[i].checkIns.append(entry)
        // Auto-complete target experiments when all milestones are reached
        if experiments[i].experimentType == .target,
           let target = experiments[i].targetCount,
           experiments[i].checkIns.filter({ $0.didComplete }).count >= target {
            experiments[i].status = .completed
            if experiments[i].endDate == nil {
                experiments[i].endDate = Date()
            }
        }
        save()
    }

    func removeCheckIn(experimentId: UUID, on date: Date) {
        guard let i = experiments.firstIndex(where: { $0.id == experimentId }) else { return }
        let cal = Calendar(identifier: .iso8601)
        experiments[i].checkIns.removeAll { $0.didComplete && cal.isDate($0.date, inSameDayAs: date) }
        save()
    }
    
    func close(experimentId: UUID, as status: ExperimentStatus, reflection: String?) {
        guard let i = experiments.firstIndex(where: { $0.id == experimentId }) else { return }
        experiments[i].status = status
        experiments[i].endDate = Date()
        experiments[i].closingReflection = reflection
        save()
    }
    
    func delete(experimentId: UUID) {
        experiments.removeAll { $0.id == experimentId }
        save()
    }
    
    func replaceAll(_ newExperiments: [Experiment]) {
        experiments = newExperiments
        save()
    }
    
    func saveCustomImage(_ image: UIImage, for experimentId: UUID) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let key = "experiment_image_\(experimentId.uuidString)"
        UserDefaults.standard.set(data, forKey: key)
        
        // Mark experiment as having custom image
        if let i = experiments.firstIndex(where: { $0.id == experimentId }) {
            experiments[i].hasCustomImage = true
            save()
        }
    }
    
    func loadCustomImage(for experimentId: UUID) -> UIImage? {
        let key = "experiment_image_\(experimentId.uuidString)"
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return UIImage(data: data)
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(experiments) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode([Experiment].self, from: data) else { return }
        experiments = saved
    }
}