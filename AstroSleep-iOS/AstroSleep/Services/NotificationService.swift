import Foundation
import UserNotifications

// MARK: - Notification Service
/// Manages bedtime reminders and local notifications.
final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized: Bool = false
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    // MARK: - Bedtime Reminder
    
    func scheduleBedtimeReminder(at date: Date) {
        // Remove existing bedtime reminders
        center.removePendingNotificationRequests(withIdentifiers: ["bedtime_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Sleep"
        content.body = "Your personalized AstroSleep session is ready. Set your intention for tonight."
        content.sound = .default
        content.categoryIdentifier = "bedtime"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "bedtime_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Bedtime reminder scheduling error: \(error)")
            }
        }
    }
    
    func cancelBedtimeReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["bedtime_reminder"])
    }
    
    // MARK: - Session Complete Notification
    
    func scheduleSessionCompleteNotification(afterMinutes minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Sleep Session Complete"
        content.body = "Your AstroSleep session has ended. Sweet dreams."
        content.sound = .none // Silent notification
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: "session_complete",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    func cancelSessionCompleteNotification() {
        center.removePendingNotificationRequests(withIdentifiers: ["session_complete"])
    }
    
    // MARK: - Subscription Reminder
    
    func scheduleTrialEndingReminder(daysRemaining: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Trial Ending Soon"
        content.body = "Your AstroSleep trial ends in \(daysRemaining) days. Upgrade to keep your personalized features."
        content.sound = .default
        
        // Schedule for tomorrow at 10 AM
        var components = DateComponents()
        components.hour = 10
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "trial_ending",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - Cleanup
    
    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}
