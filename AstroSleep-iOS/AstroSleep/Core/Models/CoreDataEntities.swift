import Foundation
import CoreData

@objc(CDUserProfile)
public class CDUserProfile: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var birthDate: Date?
    @NSManaged public var birthTime: Date?
    @NSManaged public var birthLat: Double
    @NSManaged public var birthLng: Double
    @NSManaged public var birthCity: String?
    @NSManaged public var currentLat: Double
    @NSManaged public var currentLng: Double
    @NSManaged public var currentCity: String?
    @NSManaged public var useCurrentLocationForTransits: Bool
    @NSManaged public var baseScoreFire: Double
    @NSManaged public var baseScoreEarth: Double
    @NSManaged public var baseScoreAir: Double
    @NSManaged public var baseScoreWater: Double
    @NSManaged public var natalChartJson: Data?
    @NSManaged public var cachedTier: String?
    @NSManaged public var selectedVoiceId: String?
    @NSManaged public var globalAffirmationSpeed: Double
    @NSManaged public var sleepTimerDefault: Int32
    @NSManaged public var notificationEnabled: Bool
    @NSManaged public var bedtimeReminderTime: Date?
    @NSManaged public var hasCompletedOnboarding: Bool
}

extension CDUserProfile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserProfile> {
        return NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
    }
}

@objc(CDSavedCombo)
public class CDSavedCombo: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastPlayedAt: Date?
    @NSManaged public var source: String?
    @NSManaged public var chartSnapshotJson: Data?
    @NSManaged public var layersJson: Data?
    @NSManaged public var affirmationLayerJson: Data?
    @NSManaged public var isReadOnly: Bool
}

extension CDSavedCombo {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSavedCombo> {
        return NSFetchRequest<CDSavedCombo>(entityName: "CDSavedCombo")
    }
}

@objc(CDSessionLog)
public class CDSessionLog: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var date: Date?
    @NSManaged public var intention: String?
    @NSManaged public var affirmationScript: String?
    @NSManaged public var customVoicePath: String?
    @NSManaged public var comboId: String?
    @NSManaged public var durationMinutes: Int32
    @NSManaged public var timerFired: Bool
    @NSManaged public var tier: String?
    @NSManaged public var moonPhase: String?
    @NSManaged public var layerCount: Int32
}

extension CDSessionLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSessionLog> {
        return NSFetchRequest<CDSessionLog>(entityName: "CDSessionLog")
    }
}

@objc(CDAffirmationCache)
public class CDAffirmationCache: NSManagedObject {
    @NSManaged public var calendarDate: String?
    @NSManaged public var script: String?
    @NSManaged public var generatedAt: Date?
    @NSManaged public var intention: String?
}

extension CDAffirmationCache {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAffirmationCache> {
        return NSFetchRequest<CDAffirmationCache>(entityName: "CDAffirmationCache")
    }
}
