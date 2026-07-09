import Foundation
import CoreData

// MARK: - Storage Service
/// Handles all local persistence using Core Data (iOS 16+ compatible).
/// Birth data NEVER leaves the device.
@MainActor
final class StorageService {
    static let shared = StorageService()
    
    private let container: NSPersistentContainer
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        container = NSPersistentContainer(name: "AstroSleep")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data load error: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - User Profile
    
    func saveProfile(_ profile: UserProfile) throws {
        let entity: CDUserProfile
        let request = CDUserProfile.fetchRequest()
        request.fetchLimit = 1
        let results = try context.fetch(request)
        
        if let existing = results.first {
            entity = existing
        } else {
            entity = CDUserProfile(context: context)
            entity.id = profile.id
        }
        
        entity.name = profile.name
        entity.birthDate = profile.birthDate
        entity.birthTime = profile.birthTime
        entity.birthLat = profile.birthLat
        entity.birthLng = profile.birthLng
        entity.birthCity = profile.birthCity
        entity.currentLat = profile.currentLat
        entity.currentLng = profile.currentLng
        entity.currentCity = profile.currentCity
        entity.useCurrentLocationForTransits = profile.useCurrentLocationForTransits
        entity.baseScoreFire = profile.baseScore.fire
        entity.baseScoreEarth = profile.baseScore.earth
        entity.baseScoreAir = profile.baseScore.air
        entity.baseScoreWater = profile.baseScore.water
        entity.natalChartJson = try? encoder.encode(profile.natalChart)
        entity.cachedTier = profile.cachedTierDisplayOnly.rawValue
        entity.selectedVoiceId = profile.selectedVoiceId
        entity.globalAffirmationSpeed = profile.globalAffirmationSpeed
        entity.sleepTimerDefault = Int32(profile.sleepTimerDefault)
        entity.notificationEnabled = profile.notificationEnabled
        entity.bedtimeReminderTime = profile.bedtimeReminderTime
        entity.hasCompletedOnboarding = profile.hasCompletedOnboarding
        
        try context.save()
    }
    
    func loadProfile() -> UserProfile? {
        let request = CDUserProfile.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            
            let baseScore = ElementVector(
                fire: entity.baseScoreFire,
                earth: entity.baseScoreEarth,
                air: entity.baseScoreAir,
                water: entity.baseScoreWater
            )
            
            var natalChart: NatalChart?
            if let data = entity.natalChartJson {
                natalChart = try? decoder.decode(NatalChart.self, from: data)
            }
            
            return UserProfile(
                id: entity.id ?? UUID().uuidString,
                name: entity.name ?? "",
                birthDate: entity.birthDate ?? Date(),
                birthTime: entity.birthTime,
                birthLat: entity.birthLat,
                birthLng: entity.birthLng,
                birthCity: entity.birthCity ?? "",
                currentLat: entity.currentLat,
                currentLng: entity.currentLng,
                currentCity: entity.currentCity ?? "",
                useCurrentLocationForTransits: entity.useCurrentLocationForTransits,
                baseScore: baseScore,
                natalChart: natalChart,
                cachedTierDisplayOnly: SubscriptionTier(rawValue: entity.cachedTier ?? "free") ?? .free,
                selectedVoiceId: entity.selectedVoiceId ?? "female",
                globalAffirmationSpeed: entity.globalAffirmationSpeed,
                sleepTimerDefault: Int(entity.sleepTimerDefault),
                notificationEnabled: entity.notificationEnabled,
                bedtimeReminderTime: entity.bedtimeReminderTime,
                hasCompletedOnboarding: entity.hasCompletedOnboarding
            )
        } catch {
            print("Load profile error: \(error)")
            return nil
        }
    }
    
    func updateProfile(_ update: (inout UserProfile) -> Void) throws {
        guard var profile = loadProfile() else { return }
        update(&profile)
        try saveProfile(profile)
    }
    
    // MARK: - Combos
    
    func saveCombo(_ combo: Combo) throws {
        // Check for existing
        let request = CDSavedCombo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", combo.id)
        
        let results = try context.fetch(request)
        let entity: CDSavedCombo
        
        if let existing = results.first {
            entity = existing
        } else {
            entity = CDSavedCombo(context: context)
            entity.id = combo.id
            entity.createdAt = combo.createdAt
        }
        
        entity.name = combo.name
        entity.lastPlayedAt = combo.lastPlayedAt
        entity.source = combo.source.rawValue
        entity.chartSnapshotJson = try? encoder.encode(combo.chartSnapshot)
        entity.layersJson = try? encoder.encode(combo.layers)
        entity.affirmationLayerJson = try? encoder.encode(combo.affirmationLayer)
        entity.isReadOnly = combo.isReadOnly
        
        try context.save()
    }
    
    func loadCombos() -> [Combo] {
        let request = CDSavedCombo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastPlayedAt", ascending: false)]
        
        do {
            let results = try context.fetch(request)
            return results.compactMap { entity -> Combo? in
                guard let id = entity.id,
                      let name = entity.name,
                      let createdAt = entity.createdAt,
                      let source = ComboSource(rawValue: entity.source ?? "user") else { return nil }
                
                let chartSnapshot: ChartSnapshot? = entity.chartSnapshotJson.flatMap {
                    try? self.decoder.decode(ChartSnapshot.self, from: $0)
                }
                
                let layers: [AmbientLayer] = entity.layersJson.flatMap {
                    try? self.decoder.decode([AmbientLayer].self, from: $0)
                } ?? []
                
                let affirmationLayer: AffirmationLayer = entity.affirmationLayerJson.flatMap {
                    try? self.decoder.decode(AffirmationLayer.self, from: $0)
                } ?? .default()
                
                return Combo(
                    id: id,
                    name: name,
                    createdAt: createdAt,
                    lastPlayedAt: entity.lastPlayedAt,
                    source: source,
                    chartSnapshot: chartSnapshot,
                    layers: layers,
                    affirmationLayer: affirmationLayer,
                    isReadOnly: entity.isReadOnly
                )
            }
        } catch {
            print("Load combos error: \(error)")
            return []
        }
    }
    
    func deleteCombo(id: String) throws {
        let request = CDSavedCombo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        let results = try context.fetch(request)
        for entity in results {
            context.delete(entity)
        }
        try context.save()
    }
    
    // MARK: - Session Logs
    
    func saveSessionLog(_ log: SessionLog) throws {
        let entity = CDSessionLog(context: context)
        entity.id = log.id
        entity.date = log.date
        entity.intention = log.intention
        entity.affirmationScript = log.affirmationScript
        entity.customVoicePath = log.customVoicePath
        entity.comboId = log.comboId
        entity.durationMinutes = Int32(log.durationMinutes)
        entity.timerFired = log.timerFired
        entity.tier = log.tier.rawValue
        entity.moonPhase = log.moonPhase.rawValue
        entity.layerCount = Int32(log.layerCount)
        
        try context.save()
    }
    
    func loadSessionLogs(daysLimit: Int = .max) -> [SessionLog] {
        let request = CDSessionLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        if daysLimit != .max,
           let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysLimit, to: Date()) {
            request.predicate = NSPredicate(format: "date >= %@", cutoffDate as NSDate)
        }
        
        do {
            let results = try context.fetch(request)
            return results.compactMap { entity -> SessionLog? in
                guard let id = entity.id,
                      let date = entity.date,
                      let intention = entity.intention,
                      let tierStr = entity.tier,
                      let moonPhaseStr = entity.moonPhase,
                      let moonPhase = MoonPhase(rawValue: moonPhaseStr),
                      let tier = SubscriptionTier(rawValue: tierStr) else { return nil }
                
                return SessionLog(
                    id: id,
                    date: date,
                    intention: intention,
                    affirmationScript: entity.affirmationScript ?? "",
                    customVoicePath: entity.customVoicePath,
                    comboId: entity.comboId,
                    durationMinutes: Int(entity.durationMinutes),
                    timerFired: entity.timerFired,
                    tier: tier,
                    moonPhase: moonPhase,
                    layerCount: Int(entity.layerCount)
                )
            }
        } catch {
            print("Load session logs error: \(error)")
            return []
        }
    }
    
    // MARK: - Affirmation Cache
    
    func cacheAffirmation(_ cache: AffirmationCache) throws {
        // Upsert by calendar date so we don't accumulate duplicates.
        let request = CDAffirmationCache.fetchRequest()
        request.predicate = NSPredicate(format: "calendarDate == %@", cache.id)
        request.fetchLimit = 1
        let entity: CDAffirmationCache
        if let existing = try context.fetch(request).first {
            entity = existing
        } else {
            entity = CDAffirmationCache(context: context)
            entity.calendarDate = cache.id
        }
        entity.script = cache.script
        entity.generatedAt = cache.generatedAt
        entity.intention = cache.intention
        try context.save()
    }
    
    func loadAffirmationCache(forDate dateString: String) -> AffirmationCache? {
        let request = CDAffirmationCache.fetchRequest()
        request.predicate = NSPredicate(format: "calendarDate == %@", dateString)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            guard let entity = results.first,
                  let dateStr = entity.calendarDate,
                  let script = entity.script,
                  let generatedAt = entity.generatedAt else { return nil }
            
            return AffirmationCache(
                id: dateStr,
                script: script,
                generatedAt: generatedAt,
                intention: entity.intention ?? ""
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - Delete All Data
    
    func deleteAllData() throws {
        let entities = ["CDUserProfile", "CDSavedCombo", "CDSessionLog", "CDAffirmationCache"]
        for entityName in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
            batchDelete.resultType = .resultTypeObjectIDs
            let result = try context.execute(batchDelete) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
        }
        context.reset()
        try context.save()
    }
    
    // MARK: - Sound Manifest Cache
    
    func saveSoundManifest(_ manifest: SoundManifest) throws {
        let data = try encoder.encode(manifest)
        userDefaults.set(data, forKey: "sound_manifest")
    }
    
    func loadSoundManifest() -> SoundManifest? {
        guard let data = userDefaults.data(forKey: "sound_manifest") else { return nil }
        return try? decoder.decode(SoundManifest.self, from: data)
    }
}
