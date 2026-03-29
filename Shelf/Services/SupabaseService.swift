import Foundation
import Supabase
import Combine

// MARK: - Supabase Service
// Handles all backend integration for Shelf App

@MainActor
class SupabaseService: ObservableObject {
    private let client: SupabaseClient
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    // Supabase project credentials loaded from SupabaseConfig.plist (gitignored)
    private static func loadConfig() -> (url: URL, key: String) {
        guard let path = Bundle.main.path(forResource: "SupabaseConfig", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let urlString = dict["SupabaseURL"] as? String,
              let url = URL(string: urlString),
              let key = dict["SupabaseAnonKey"] as? String
        else {
            fatalError("SupabaseConfig.plist missing or malformed. Copy SupabaseConfig.example.plist to SupabaseConfig.plist and fill in your credentials.")
        }
        return (url, key)
    }

    init() {
        let config = Self.loadConfig()
        self.client = SupabaseClient(
            supabaseURL: config.url,
            supabaseKey: config.key
        )
        
        // Check if user is already authenticated
        Task {
            await checkAuthState()
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, displayName: String) async throws -> User {
        let session = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        // Create user profile
        let userProfile = UserProfile(
            id: session.user.id,
            email: email,
            displayName: displayName,
            username: generateUsername(from: displayName)
        )
        
        try await createUserProfile(userProfile)
        
        await checkAuthState()
        return session.user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        await checkAuthState()
        return session.user
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    private func checkAuthState() async {
        do {
            currentUser = try await client.auth.user()
            isAuthenticated = currentUser != nil
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    // MARK: - User Management
    
    private func createUserProfile(_ profile: UserProfile) async throws {
        let _: UserProfile = try await client
            .from("users")
            .insert(profile)
            .select()
            .single()
            .execute()
            .value
    }
    
    func getUserProfile(userId: UUID) async throws -> UserProfile {
        let profile: UserProfile = try await client
            .from("users")
            .select("*")
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return profile
    }
    
    func updatePremiumStatus(userId: UUID, isPremium: Bool, expiresAt: Date?) async throws {
        struct PremiumUpdate: Encodable {
            let isPremium: Bool
            let premiumExpiresAt: String?
            enum CodingKeys: String, CodingKey {
                case isPremium = "is_premium"
                case premiumExpiresAt = "premium_expires_at"
            }
        }
        try await client
            .from("users")
            .update(PremiumUpdate(isPremium: isPremium, premiumExpiresAt: expiresAt?.ISO8601Format()))
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Experiments
    
    func createExperiment(_ experiment: ExperimentData) async throws -> ExperimentData {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        var experimentToCreate = experiment
        experimentToCreate.userId = userId
        
        let created: ExperimentData = try await client
            .from("experiments")
            .insert(experimentToCreate)
            .select("*")
            .single()
            .execute()
            .value
        
        return created
    }
    
    func getUserExperiments() async throws -> [ExperimentData] {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let experiments: [ExperimentData] = try await client
            .from("experiments")
            .select("*, check_ins(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return experiments
    }
    
    func getPublicExperiments(limit: Int = 50) async throws -> [ExperimentData] {
        let experiments: [ExperimentData] = try await client
            .from("experiments")
            .select("*, users(display_name, username), check_ins(*)")
            .eq("is_public", value: true)
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return experiments
    }
    
    func updateExperiment(_ experiment: ExperimentData) async throws -> ExperimentData {
        struct ExperimentUpdate: Encodable {
            let name: String
            let intention: String?
            let experimentType: String
            let frequency: String?
            let timesPerWeek: Int?
            let targetCount: Int?
            let durationDays: Int?
            let status: String
            let isPublic: Bool
            let iconPreset: String
            let hasCustomImage: Bool
            let closingReflection: String?
            let updatedAt: String
            enum CodingKeys: String, CodingKey {
                case name, intention, frequency, status
                case experimentType = "experiment_type"
                case timesPerWeek = "times_per_week"
                case targetCount = "target_count"
                case durationDays = "duration_days"
                case isPublic = "is_public"
                case iconPreset = "icon_preset"
                case hasCustomImage = "has_custom_image"
                case closingReflection = "closing_reflection"
                case updatedAt = "updated_at"
            }
        }
        let updated: ExperimentData = try await client
            .from("experiments")
            .update(ExperimentUpdate(
                name: experiment.name,
                intention: experiment.intention,
                experimentType: experiment.experimentType,
                frequency: experiment.frequency,
                timesPerWeek: experiment.timesPerWeek,
                targetCount: experiment.targetCount,
                durationDays: experiment.durationDays,
                status: experiment.status,
                isPublic: experiment.isPublic,
                iconPreset: experiment.iconPreset,
                hasCustomImage: experiment.hasCustomImage,
                closingReflection: experiment.closingReflection,
                updatedAt: Date().ISO8601Format()
            ))
            .eq("id", value: experiment.id)
            .select("*")
            .single()
            .execute()
            .value

        return updated
    }
    
    func deleteExperiment(_ experimentId: UUID) async throws {
        try await client
            .from("experiments")
            .delete()
            .eq("id", value: experimentId)
            .execute()
    }
    
    // MARK: - Check-ins
    
    func addCheckIn(experimentId: UUID, note: String? = nil) async throws -> CheckInData {
        let checkIn = CheckInData(
            experimentId: experimentId,
            date: Date(),
            didComplete: true,
            note: note
        )
        
        let created: CheckInData = try await client
            .from("check_ins")
            .insert(checkIn)
            .select("*")
            .single()
            .execute()
            .value
        
        return created
    }
    
    // MARK: - Social Features
    
    func likeExperiment(_ experimentId: UUID) async throws {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let like = ExperimentLike(experimentId: experimentId, userId: userId)
        
        let _: ExperimentLike = try await client
            .from("experiment_likes")
            .insert(like)
            .execute()
            .value
    }
    
    func unlikeExperiment(_ experimentId: UUID) async throws {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        try await client
            .from("experiment_likes")
            .delete()
            .eq("experiment_id", value: experimentId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    // MARK: - Image Upload
    
    func uploadExperimentImage(_ imageData: Data, experimentId: UUID) async throws -> String {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let fileName = "\(userId)/\(experimentId).jpg"
        
        try await client.storage
            .from("experiment-images")
            .upload(fileName, data: imageData)
        
        let url = try client.storage
            .from("experiment-images")
            .getPublicURL(path: fileName)
        
        return url.absoluteString
    }
    
    // MARK: - Utilities
    
    private func generateUsername(from displayName: String) -> String {
        let cleaned = displayName.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
        
        let random = String(Int.random(in: 1000...9999))
        return "\(cleaned)\(random)"
    }
}

// MARK: - Data Models

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let email: String
    var displayName: String?
    var username: String?
    var avatarUrl: String?
    let createdAt: Date?
    var lastSeen: Date?
    var premiumExpiresAt: Date?
    var isPremium: Bool
    var experimentCount: Int
    let maxFreeExperiments: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case username
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case lastSeen = "last_seen"
        case premiumExpiresAt = "premium_expires_at"
        case isPremium = "is_premium"
        case experimentCount = "experiment_count"
        case maxFreeExperiments = "max_free_experiments"
    }
    
    init(id: UUID, email: String, displayName: String?, username: String?) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.username = username
        self.avatarUrl = nil
        self.createdAt = nil
        self.lastSeen = nil
        self.premiumExpiresAt = nil
        self.isPremium = false
        self.experimentCount = 0
        self.maxFreeExperiments = 3
    }
}

struct ExperimentData: Codable, Identifiable {
    let id: UUID
    var userId: UUID?
    var name: String
    var intention: String?
    var experimentType: String
    var frequency: String?
    var timesPerWeek: Int?
    var targetCount: Int?
    var durationDays: Int?
    let startDate: Date
    var endDate: Date?
    var status: String
    var isPublic: Bool
    var iconPreset: String
    var hasCustomImage: Bool
    var customImageUrl: String?
    var closingReflection: String?
    let createdAt: Date?
    var updatedAt: Date?

    // Relations
    var checkIns: [CheckInData]?
    var author: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case intention
        case experimentType = "experiment_type"
        case frequency
        case timesPerWeek = "times_per_week"
        case targetCount = "target_count"
        case durationDays = "duration_days"
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case isPublic = "is_public"
        case iconPreset = "icon_preset"
        case hasCustomImage = "has_custom_image"
        case customImageUrl = "custom_image_url"
        case closingReflection = "closing_reflection"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case checkIns = "check_ins"
        case author = "users"
    }

    init(from experiment: Experiment) {
        self.id = experiment.id
        self.userId = nil // Will be set by service
        self.name = experiment.name
        self.intention = experiment.intention
        self.experimentType = experiment.experimentType.rawValue
        self.frequency = experiment.frequency?.rawValue
        self.timesPerWeek = experiment.timesPerWeek
        self.targetCount = experiment.targetCount
        self.durationDays = experiment.durationDays
        self.startDate = experiment.startDate
        self.endDate = experiment.endDate
        self.status = experiment.status.rawValue
        self.isPublic = experiment.isPublic
        self.iconPreset = experiment.iconPreset.rawValue
        self.hasCustomImage = experiment.hasCustomImage
        self.customImageUrl = nil
        self.closingReflection = experiment.closingReflection
        self.createdAt = nil
        self.updatedAt = nil
        self.checkIns = experiment.checkIns.map(CheckInData.init)
        self.author = nil
    }

}

// MARK: - Backward-compatible decoder (extension preserves synthesised memberwise init)

extension ExperimentData {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,            forKey: .id)
        userId           = try c.decodeIfPresent(UUID.self,   forKey: .userId)
        name             = try c.decode(String.self,          forKey: .name)
        intention        = try c.decodeIfPresent(String.self, forKey: .intention)
        experimentType   = try c.decodeIfPresent(String.self, forKey: .experimentType) ?? "habit"
        frequency        = try c.decodeIfPresent(String.self, forKey: .frequency)
        timesPerWeek     = try c.decodeIfPresent(Int.self,    forKey: .timesPerWeek)
        targetCount      = try c.decodeIfPresent(Int.self,    forKey: .targetCount)
        durationDays     = try c.decodeIfPresent(Int.self,    forKey: .durationDays)
        startDate        = try c.decode(Date.self,            forKey: .startDate)
        endDate          = try c.decodeIfPresent(Date.self,   forKey: .endDate)
        status           = try c.decode(String.self,          forKey: .status)
        isPublic         = try c.decodeIfPresent(Bool.self,   forKey: .isPublic)         ?? true
        iconPreset       = try c.decodeIfPresent(String.self, forKey: .iconPreset)       ?? "book.closed"
        hasCustomImage   = try c.decodeIfPresent(Bool.self,   forKey: .hasCustomImage)   ?? false
        customImageUrl   = try c.decodeIfPresent(String.self, forKey: .customImageUrl)
        closingReflection = try c.decodeIfPresent(String.self, forKey: .closingReflection)
        createdAt        = try c.decodeIfPresent(Date.self,   forKey: .createdAt)
        updatedAt        = try c.decodeIfPresent(Date.self,   forKey: .updatedAt)
        checkIns         = try c.decodeIfPresent([CheckInData].self, forKey: .checkIns) ?? []
        author           = try c.decodeIfPresent(UserProfile.self,   forKey: .author)
    }
}

struct CheckInData: Codable, Identifiable {
    let id: UUID?
    let experimentId: UUID
    let date: Date
    let didComplete: Bool
    let note: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case experimentId = "experiment_id"
        case date
        case didComplete = "did_complete"
        case note
        case createdAt = "created_at"
    }
    
    init(experimentId: UUID, date: Date, didComplete: Bool, note: String?) {
        self.id = nil
        self.experimentId = experimentId
        self.date = date
        self.didComplete = didComplete
        self.note = note
        self.createdAt = nil
    }
    
    nonisolated init(from checkIn: CheckIn) {
        self.id = checkIn.id
        self.experimentId = UUID() // Will be set by parent
        self.date = checkIn.date
        self.didComplete = checkIn.didComplete
        self.note = checkIn.note
        self.createdAt = nil
    }
}

struct ExperimentLike: Codable {
    let experimentId: UUID
    let userId: UUID
    
    enum CodingKeys: String, CodingKey {
        case experimentId = "experiment_id"
        case userId = "user_id"
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case premiumRequired
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .premiumRequired:
            return "This feature requires a premium subscription"
        case .networkError(let message):
            return message
        }
    }
}