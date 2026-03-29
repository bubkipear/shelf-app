import Foundation
import SwiftUI

// MARK: - Enums

enum ExperimentType: String, Codable {
    case habit
    case target
}

enum CheckInFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case severalTimesWeek = "A few times a week"
    case weekly = "Weekly"
}

enum ExperimentState {
    case onTrack
    case missed
    case offTrack
    case abandoned
    case completed
}

enum ExperimentStatus: String, Codable {
    case active
    case abandoned
    case completed
}

// MARK: - Experiment Icon

enum ExperimentIcon: String, Codable, CaseIterable {
    case book        = "book.closed"
    case ball        = "soccerball"
    case plant       = "leaf"
    case mug         = "cup.and.saucer"
    case camera      = "camera"
    case weights     = "dumbbell"
    case bike        = "bicycle"
    case brush       = "paintbrush"
    case headphones  = "headphones"
    case music       = "music.note"
    case run         = "figure.run"
    case cook        = "fork.knife"

    // Bundled photorealistic sticker, if one exists for this icon type
    var stickerImageName: String? {
        switch self {
        case .mug:  return "coffee"
        case .cook: return "cook"
        case .book: return "pages"
        default:    return nil
        }
    }

    var label: String {
        switch self {
        case .book:       return "Book"
        case .ball:       return "Ball"
        case .plant:      return "Plant"
        case .mug:        return "Mug"
        case .camera:     return "Camera"
        case .weights:    return "Weights"
        case .bike:       return "Bike"
        case .brush:      return "Brush"
        case .headphones: return "Headphones"
        case .music:      return "Music"
        case .run:        return "Running"
        case .cook:       return "Cooking"
        }
    }
}

// MARK: - CheckIn

struct CheckIn: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var didComplete: Bool
    var note: String?
}

// MARK: - Experiment

struct Experiment: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var intention: String?
    var experimentType: ExperimentType = .habit
    var frequency: CheckInFrequency?
    var timesPerWeek: Int?              // used when frequency == .severalTimesWeek
    var targetCount: Int?               // used when experimentType == .target
    var durationDays: Int?
    var startDate: Date = Date()
    var endDate: Date?
    var status: ExperimentStatus = .active
    var isPublic: Bool = true
    var iconPreset: ExperimentIcon = .book
    var hasCustomImage: Bool = false
    var checkIns: [CheckIn] = []
    var closingReflection: String?

    // MARK: Computed

    var experimentState: ExperimentState {
        guard status == .active else {
            return status == .abandoned ? .abandoned : .completed
        }
        // Off track: past end date / deadline without completing
        if let end = endDate, Date() > end {
            return .offTrack
        }
        // Target experiments are on track as long as they're within deadline (or have no deadline)
        if experimentType == .target {
            return .onTrack
        }
        // Habit: assess recency of check-ins against frequency-based threshold
        let threshold = missedThreshold
        if let days = daysSinceLastCheckIn {
            return days > threshold ? .missed : .onTrack
        } else {
            // No check-ins yet — missed if the experiment has been running long enough
            return daysSinceStart > threshold ? .missed : .onTrack
        }
    }

    // How many days without a check-in before a habit is considered "missed"
    private var missedThreshold: Int {
        switch frequency {
        case .daily:            return 1
        case .severalTimesWeek: return 2
        case .weekly:           return 7
        case .none:             return 2
        }
    }

    var daysSinceLastCheckIn: Int? {
        let completions = checkIns.filter { $0.didComplete }
        guard let last = completions.sorted(by: { $0.date > $1.date }).first else { return nil }
        return Calendar.current.dateComponents([.day], from: last.date, to: Date()).day
    }

    var currentStreakDays: Int {
        let sorted = checkIns.filter { $0.didComplete }.sorted(by: { $0.date > $1.date })
        var streak = 0
        var reference = Date()
        for checkIn in sorted {
            let diff = Calendar.current.dateComponents([.day], from: checkIn.date, to: reference).day ?? 0
            if diff <= 1 { streak += 1; reference = checkIn.date } else { break }
        }
        return streak
    }

    var totalCheckIns: Int { checkIns.filter { $0.didComplete }.count }

    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }

    // Deterministic tilt angle from UUID — -6 to +6 degrees
    var tiltDegrees: Double {
        let hash = abs(id.hashValue % 1000)
        return (Double(hash) / 1000.0 - 0.5) * 12
    }
}

// MARK: - Backward-compatible decoder (extension preserves synthesised memberwise init)

extension Experiment {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decodeIfPresent(UUID.self,             forKey: .id)               ?? UUID()
        name             = try c.decode(String.self,                    forKey: .name)
        intention        = try c.decodeIfPresent(String.self,           forKey: .intention)
        experimentType   = try c.decodeIfPresent(ExperimentType.self,   forKey: .experimentType)   ?? .habit
        frequency        = try c.decodeIfPresent(CheckInFrequency.self, forKey: .frequency)
        timesPerWeek     = try c.decodeIfPresent(Int.self,              forKey: .timesPerWeek)
        targetCount      = try c.decodeIfPresent(Int.self,              forKey: .targetCount)
        durationDays     = try c.decodeIfPresent(Int.self,              forKey: .durationDays)
        startDate        = try c.decodeIfPresent(Date.self,             forKey: .startDate)        ?? Date()
        endDate          = try c.decodeIfPresent(Date.self,             forKey: .endDate)
        status           = try c.decodeIfPresent(ExperimentStatus.self, forKey: .status)           ?? .active
        isPublic         = try c.decodeIfPresent(Bool.self,             forKey: .isPublic)         ?? true
        iconPreset       = try c.decodeIfPresent(ExperimentIcon.self,   forKey: .iconPreset)       ?? .book
        hasCustomImage   = try c.decodeIfPresent(Bool.self,             forKey: .hasCustomImage)   ?? false
        checkIns         = try c.decodeIfPresent([CheckIn].self,        forKey: .checkIns)         ?? []
        closingReflection = try c.decodeIfPresent(String.self,          forKey: .closingReflection)
    }
}
