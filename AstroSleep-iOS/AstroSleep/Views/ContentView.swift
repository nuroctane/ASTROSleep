import SwiftUI

// MARK: - Content View
/// Root view that manages app-level navigation and screen flow.
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ZStack {
            switch appState.currentScreen {
            case .onboarding:
                OnboardingFlowView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            
            case .main:
                MainTabView()
                    .transition(.opacity)
            
            case .playback(let combo):
                PlaybackView(combo: combo)
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            
            case .comboBuilder(let combo):
                ComboBuilderView(existingCombo: combo)
                    .transition(.move(edge: .trailing))
            
            case .paywall(let trigger):
                PaywallView(triggerFeature: trigger)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
        .overlay {
            if appState.isLoading {
                LoadingOverlay()
            }
        }
        .overlay {
            if let error = appState.errorMessage {
                ErrorBanner(message: error)
            }
        }
        .sheet(isPresented: $appState.showPaywall) {
            PaywallView(triggerFeature: appState.paywallTrigger)
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: TabSelection = .tonight
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TonightView()
                .tabItem {
                    Label(TabSelection.tonight.rawValue, systemImage: TabSelection.tonight.icon)
                }
                .tag(TabSelection.tonight)
            
            SoundLibraryView()
                .tabItem {
                    Label(TabSelection.sounds.rawValue, systemImage: TabSelection.sounds.icon)
                }
                .tag(TabSelection.sounds)
            
            PlaylistLibraryView()
                .tabItem {
                    Label(TabSelection.library.rawValue, systemImage: TabSelection.library.icon)
                }
                .tag(TabSelection.library)
            
            SettingsView()
                .tabItem {
                    Label(TabSelection.settings.rawValue, systemImage: TabSelection.settings.icon)
                }
                .tag(TabSelection.settings)
        }
        .tint(ThemeService.shared.accentColor)
        // iOS 26 Liquid Glass: floating tab bar minimizes while scrolling content.
        .astroTabBarLiquidGlass()
        .onChange(of: selectedTab) { oldValue, newValue in
            appState.selectedTab = newValue
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Loading...")
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding(24)
            .astroGlassCard(cornerRadius: 20)
        }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    appState.errorMessage = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .astroGlassCard(cornerRadius: 14)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 8)
        .transition(.move(edge: .top))
    }
}
