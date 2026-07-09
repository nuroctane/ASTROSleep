import Foundation
import Combine

// MARK: - App State
/// Central application state observable by all views.
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var currentScreen: AppScreen = .onboarding
    @Published var selectedTab: TabSelection = .tonight
    @Published var profile: UserProfile?
    @Published var currentTier: SubscriptionTier = .free
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var activeCombo: Combo?
    @Published var currentNightlyScore: NightlyScoreResult?
    @Published var cachedAffirmation: String?
    @Published var showPaywall: Bool = false
    @Published var paywallTrigger: String = ""
    /// Tag Engine v4 personal fingerprint (stable per user + chart). Quiet UI / debug.
    @Published var personalFingerprint: Int64?
    @Published var rankedPreview: [RankedSound] = []
    
    private var lastNightlyScoreDate: Date?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadProfile()
        RevenueCatService.shared.$currentTier
            .sink { [weak self] tier in
                self?.currentTier = tier
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Profile Management
    
    func loadProfile() {
        if let profile = StorageService.shared.loadProfile() {
            self.profile = profile
            self.currentScreen = profile.hasCompletedOnboarding ? .main : .onboarding
        } else {
            self.currentScreen = .onboarding
        }
    }
    
    func createProfile(name: String, birthDate: Date, birthTime: Date?, birthLat: Double, birthLng: Double, birthCity: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Compute natal chart
        let chart = AstrologicalEngine.shared.computeNatalChart(
            birthDate: birthDate,
            birthTime: birthTime,
            lat: birthLat,
            lng: birthLng
        )
        
        let baseScore = AstrologicalEngine.shared.deriveBaseScore(from: chart)
        
        let profile = UserProfile(
            id: AuthService.shared.currentUserId ?? UUID().uuidString,
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            birthLat: birthLat,
            birthLng: birthLng,
            birthCity: birthCity,
            currentLat: 0,
            currentLng: 0,
            currentCity: "",
            useCurrentLocationForTransits: false,
            baseScore: baseScore,
            natalChart: chart,
            hasCompletedOnboarding: true
        )
        
        try StorageService.shared.saveProfile(profile)
        self.profile = profile
    }
    
    /// Updates birth data, recomputes the natal chart, and invalidates cached scores.
    func updateBirthData(
        name: String,
        birthDate: Date,
        birthTime: Date?,
        birthCity: String
    ) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await GeocodingService.shared.geocode(city: birthCity)
        
        let chart = AstrologicalEngine.shared.computeNatalChart(
            birthDate: birthDate,
            birthTime: birthTime,
            lat: result.lat,
            lng: result.lng
        )
        
        let baseScore = AstrologicalEngine.shared.deriveBaseScore(from: chart)
        
        try StorageService.shared.updateProfile { profile in
            profile.name = name
            profile.birthDate = birthDate
            profile.birthTime = birthTime
            profile.birthLat = result.lat
            profile.birthLng = result.lng
            profile.birthCity = result.city
            profile.natalChart = chart
            profile.baseScore = baseScore
        }
        
        // Invalidate cached scores so they recompute with the new birth data
        lastNightlyScoreDate = nil
        currentNightlyScore = nil
        
        loadProfile()
        computeNightlyScore()
    }
    
    // MARK: - Nightly Score
    
    func computeNightlyScore() {
        guard let profile = profile, let chart = profile.natalChart else { return }
        
        // Cache: score only changes meaningfully once per day
        let calendar = Calendar.current
        let now = Date()
        if let lastDate = lastNightlyScoreDate,
           calendar.isDate(lastDate, inSameDayAs: now),
           currentNightlyScore != nil {
            return // Use cached score for same calendar day
        }
        
        // Prefer current location when enabled; otherwise birth place (never 0,0).
        let transitLat = profile.useCurrentLocationForTransits ? profile.currentLat : profile.birthLat
        let transitLng = profile.useCurrentLocationForTransits ? profile.currentLng : profile.birthLng
        let score = AstrologicalEngine.shared.calculateNightlyScore(
            baseScore: profile.baseScore,
            date: now,
            natalChart: chart,
            currentLat: transitLat,
            currentLng: transitLng,
            useCurrentLocation: true // always pass resolved coordinates
        )
        
        currentNightlyScore = score
        lastNightlyScoreDate = now
    }
    
    // MARK: - Affirmation
    
    func getOrCreateAffirmation(intention: String) async -> String? {
        let calendar = Calendar.current
        let dateString = formatDate(calendar.startOfDay(for: Date()))
        
        // Check cache
        if let cache = StorageService.shared.loadAffirmationCache(forDate: dateString) {
            cachedAffirmation = cache.script
            return cache.script
        }
        
        // Prefer authenticated user id; fall back to stable local profile id for guest MVP.
        let userId = AuthService.shared.currentUserId
            ?? profile?.id
            ?? "guest"
        
        do {
            let script = try await NetworkService.shared.generateAffirmation(
                intention: intention,
                userId: userId
            )
            
            let cache = AffirmationCache(
                id: dateString,
                script: script,
                generatedAt: Date(),
                intention: intention
            )
            try StorageService.shared.cacheAffirmation(cache)
            cachedAffirmation = script
            return script
        } catch NetworkError.rateLimited {
            return nil
        } catch {
            return nil
        }
    }
    
    // MARK: - Combo Generation
    
    /// Auto combo via Tag Engine v4 + ComboComposer (parity with Android).
    func autoGenerateCombo(intention: String, tier: SubscriptionTier) -> Combo {
        computeNightlyScore()
        
        guard let score = currentNightlyScore else {
            return createDefaultCombo(intention: intention, tier: tier)
        }
        
        let userId = AuthService.shared.currentUserId
            ?? profile?.id
            ?? UUID().uuidString
        let baseScore = profile?.baseScore ?? score.elementScore
        let chart = profile?.natalChart
        
        let result = ComboComposer.shared.compose(
            userId: userId,
            sounds: SoundLibrary.shared.sounds,
            nightly: score,
            natalBaseScore: baseScore,
            chart: chart,
            tier: tier,
            voiceId: profile?.selectedVoiceId ?? "female"
        )
        
        personalFingerprint = result.profile.fingerprint
        rankedPreview = Array(result.ranked.prefix(12))
        activeCombo = result.combo
        return result.combo
    }
    
    /// Recompute ranked preview without building a full combo (Sounds tab / debug).
    func refreshRankedPreview() {
        guard let profile = profile, let score = currentNightlyScore else { return }
        let personal = PersonalSoundProfile.from(
            userId: profile.id,
            chart: profile.natalChart,
            baseScore: profile.baseScore
        )
        let ranked = TagEngine.shared.rankSoundsPersonalized(
            sounds: SoundLibrary.shared.sounds,
            nightly: score,
            profile: personal,
            natalBaseScore: profile.baseScore,
            chart: profile.natalChart
        )
        personalFingerprint = personal.fingerprint
        rankedPreview = Array(ranked.prefix(12))
    }
    
    private func createDefaultCombo(intention: String, tier: SubscriptionTier) -> Combo {
        let sounds = SoundLibrary.shared.sounds
        let maxLayers = tier.maxLayers
        let selected = sounds.prefix(maxLayers)
        
        let layers = selected.map { sound in
            AmbientLayer(
                soundId: sound.id,
                volume: 0.5,
                playbackSpeed: 1.0,
                eq: .default,
                oscillation: nil
            )
        }
        
        return Combo(
            id: UUID().uuidString,
            name: "Tonight's Session",
            createdAt: Date(),
            source: .auto,
            chartSnapshot: nil,
            layers: Array(layers),
            affirmationLayer: .default(),
            isReadOnly: false
        )
    }
    
    // MARK: - Tier Enforcement
    
    func enforceTier(_ requiredTier: SubscriptionTier, for feature: String) -> Bool {
        if currentTier < requiredTier {
            paywallTrigger = feature
            showPaywall = true
            return false
        }
        return true
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}
