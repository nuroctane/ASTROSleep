import SwiftUI

@main
struct AstroSleepApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppState.shared)
                .environmentObject(AudioService.shared)
                .environmentObject(AuthService.shared)
                .environmentObject(RevenueCatService.shared)
                .environmentObject(NotificationService.shared)
                .environmentObject(ThemeService.shared)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure appearance
        configureAppearance()
        
        // Setup notifications
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: connectingSceneSession.configuration.name,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    
    private func configureAppearance() {
        // Liquid Glass (iOS 26+): avoid opaque nav/tab chrome that overlays system glass.
        // On iOS 26, transparent / default appearances let TabView + NavigationStack float in glass.
        if #available(iOS 26.0, *) {
            let nav = UINavigationBarAppearance()
            nav.configureWithDefaultBackground() // system-managed material / glass
            nav.titleTextAttributes = [.foregroundColor: UIColor.label]
            nav.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            UINavigationBar.appearance().standardAppearance = nav
            UINavigationBar.appearance().compactAppearance = nav
            UINavigationBar.appearance().scrollEdgeAppearance = nav
            UINavigationBar.appearance().compactScrollEdgeAppearance = nav
            
            let tab = UITabBarAppearance()
            tab.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = tab
            UITabBar.appearance().scrollEdgeAppearance = tab
        } else {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Scene Delegate

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Handle deep links on app launch
        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(url: urlContext.url)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleDeepLink(url: url)
        }
    }
    
    private func handleDeepLink(url: URL) {
        // Handle password reset deep links
        if url.host == "astrosleep.app" && url.path == "/reset-password" {
            // Extract token from URL and navigate to reset screen
            NotificationCenter.default.post(name: .passwordResetDeepLink, object: url)
        }
    }
}

// MARK: - Notification Delegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let identifier = response.notification.request.identifier
        
        if identifier == "bedtime_reminder" {
            // Navigate to Tonight screen
            Task { @MainActor in
                AppState.shared.selectedTab = .tonight
            }
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let passwordResetDeepLink = Notification.Name("passwordResetDeepLink")
}
