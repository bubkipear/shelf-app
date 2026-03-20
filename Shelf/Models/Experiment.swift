import Foundation
import SwiftUI

// MARK: - Enums

enum CheckInFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case severalTimesWeek = "A few times a week"
    case weekly = "Weekly"
}

enum ExperimentState {
    case tended
    case neglected
    case adrift
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
    var frequency: CheckInFrequency?
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
        guard let daysSinceLast = daysSinceLastCheckIn else { return .adrift }
        switch daysSinceLast {
        case 0...2:  return .tended
        case 3...7:  return .neglected
        default:     return .adrift
        }
    }

    var brightness: Double {
        switch experimentState {
        case .tended:    return 1.0
        case .neglected: return 0.6
        case .adrift:    return 0.3
        case .abandoned: return 0.15
        case .completed: return 0.8
        }
    }

    var daysSinceLastCheckIn: Int? {
        guard let last = checkIns.sorted(by: { $0.date > $1.date }).first else { return nil }
        return Calendar.current.dateComponents([.day], from: last.date, to: Date()).day
    }

    var currentStreakDays: Int {
        let sorted = checkIns.sorted(by: { $0.date > $1.date })
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
