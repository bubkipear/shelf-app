import Foundation
import SwiftUI

// MARK: - Enums

enum CheckInFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case severalTimesWeek = "A few times a week"
    case weekly = "Weekly"
}

enum PlanetState {
    case tended       // checked in recently, bright + pulsing
    case neglected    // missed a few check-ins, dim
    case adrift       // long absence, very faint
    case abandoned    // intentionally closed
    case completed    // finished, in constellation
}

enum ExperimentStatus: String, Codable {
    case active
    case abandoned
    case completed
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
    var durationDays: Int?           // nil = open-ended
    var startDate: Date = Date()
    var endDate: Date?
    var status: ExperimentStatus = .active
    var isPublic: Bool = true
    var planetAsset: String          // e.g. "planet_01", "planet_02" — maps to GIF name
    var checkIns: [CheckIn] = []
    var closingReflection: String?

    // MARK: Computed

    var planetState: PlanetState {
        guard status == .active else {
            return status == .abandoned ? .abandoned : .completed
        }
        let daysSinceLast = daysSinceLastCheckIn
        switch daysSinceLast {
        case .none:      return .adrift
        case 0...2:      return .tended
        case 3...7:      return .neglected
        default:         return .adrift
        }
    }

    var brightness: Double {
        switch planetState {
        case .tended:    return 1.0
        case .neglected: return 0.5
        case .adrift:    return 0.2
        case .abandoned: return 0.12
        case .completed: return 0.75
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
}

// MARK: - Planet Palette

struct PlanetPalette {
    let primary: Color
    let glow: Color
    let ring: Color?

    static let all: [String: PlanetPalette] = [
        "planet_01": PlanetPalette(primary: .init(red: 0.4, green: 0.7, blue: 1.0),   glow: .blue,   ring: .init(red: 0.6, green: 0.85, blue: 1.0)),
        "planet_02": PlanetPalette(primary: .init(red: 1.0, green: 0.5, blue: 0.3),   glow: .orange, ring: nil),
        "planet_03": PlanetPalette(primary: .init(red: 0.6, green: 1.0, blue: 0.6),   glow: .green,  ring: .init(red: 0.4, green: 0.9, blue: 0.4)),
        "planet_04": PlanetPalette(primary: .init(red: 0.9, green: 0.5, blue: 1.0),   glow: .purple, ring: nil),
        "planet_05": PlanetPalette(primary: .init(red: 1.0, green: 0.9, blue: 0.4),   glow: .yellow, ring: .init(red: 1.0, green: 0.95, blue: 0.6)),
        "planet_06": PlanetPalette(primary: .init(red: 1.0, green: 0.35, blue: 0.5),  glow: .red,    ring: nil),
        "planet_07": PlanetPalette(primary: .init(red: 0.4, green: 0.9, blue: 0.95),  glow: .cyan,   ring: .init(red: 0.5, green: 0.95, blue: 1.0)),
        "planet_08": PlanetPalette(primary: .init(red: 1.0, green: 0.7, blue: 0.3),   glow: .orange, ring: nil),
        "planet_09": PlanetPalette(primary: .init(red: 0.7, green: 0.6, blue: 1.0),   glow: .indigo, ring: .init(red: 0.8, green: 0.75, blue: 1.0)),
        "planet_10": PlanetPalette(primary: .init(red: 0.3, green: 1.0, blue: 0.8),   glow: .mint,   ring: nil),
        "planet_11": PlanetPalette(primary: .init(red: 1.0, green: 0.6, blue: 0.8),   glow: .pink,   ring: .init(red: 1.0, green: 0.75, blue: 0.9)),
        "planet_12": PlanetPalette(primary: .init(red: 0.8, green: 0.95, blue: 0.5),  glow: .yellow, ring: nil),
    ]

    static func palette(for asset: String) -> PlanetPalette {
        all[asset] ?? PlanetPalette(primary: .white, glow: .white, ring: nil)
    }
}
