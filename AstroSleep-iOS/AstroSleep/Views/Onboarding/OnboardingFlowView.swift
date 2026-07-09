import SwiftUI

// MARK: - Onboarding Flow
/// Multi-step onboarding: intro -> birth data -> account -> subscription preview.
struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep: OnboardingStep = .intro
    @State private var profileData = OnboardingProfileData()
    @State private var showingBirthData = false
    
    enum OnboardingStep {
        case intro
        case birthData
        // case account // Optional for MVP
        case complete
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                switch currentStep {
                case .intro:
                    IntroStepView(onContinue: {
                        withAnimation {
                            currentStep = .birthData
                        }
                    })
                case .birthData:
                    BirthDataEntryStepView(
                        profileData: $profileData,
                        onComplete: { name, date, time, lat, lng, city in
                            Task {
                                do {
                                    try await appState.createProfile(
                                        name: name,
                                        birthDate: date,
                                        birthTime: time,
                                        birthLat: lat,
                                        birthLng: lng,
                                        birthCity: city
                                    )
                                    withAnimation {
                                        currentStep = .complete
                                    }
                                } catch {
                                    appState.errorMessage = "Failed to create profile: \(error.localizedDescription)"
                                }
                            }
                        }
                    )
                case .complete:
                    OnboardingCompleteView(onStart: {
                        withAnimation {
                            appState.currentScreen = .main
                        }
                    })
                }
            }
        }
    }
}

// MARK: - Intro Step

struct IntroStepView: View {
    let onContinue: () -> Void
    @State private var currentPage = 0
    
    let pages = [
        IntroPage(
            title: "Sleep with Intention",
            description: "AstroSleep curates your sonic environment based on your astrological chart and the current night sky.",
            icon: "moon.stars.fill",
            useAppLogo: true
        ),
        IntroPage(
            title: "Astrological Personalization",
            description: "Your natal chart and live transits guide sound recommendations tailored to your energetic state.",
            icon: "star.circle.fill",
            useAppLogo: false
        ),
        IntroPage(
            title: "Subliminal Affirmations",
            description: "Set an intention and receive AI-generated affirmations that play softly beneath your sleep sounds.",
            icon: "waveform",
            useAppLogo: false
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    IntroPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxHeight: .infinity)
            
            VStack(spacing: 16) {
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ThemeService.shared.accentColor)
                        .cornerRadius(14)
                }
                
                Button(action: {
                    onContinue()
                }) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
}

struct IntroPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    var useAppLogo: Bool = false
}

struct IntroPageView: View {
    let page: IntroPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if page.useAppLogo {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.indigo.opacity(0.35), radius: 16, y: 8)
            } else {
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundColor(ThemeService.shared.accentColor)
                    .symbolRenderingMode(.multicolor)
            }
            
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

// MARK: - Birth Data Entry Step

struct BirthDataEntryStepView: View {
    @Binding var profileData: OnboardingProfileData
    let onComplete: (String, Date, Date?, Double, Double, String) -> Void
    
    @State private var name = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var birthTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var hasInteractedWithTimePicker = false
    @State private var birthCity = ""
    @State private var isComputing = false
    @State private var showingPrivacyInfo = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Birth Data")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your birth data is stored only on this device and is never uploaded.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.headline)
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                }
                
                // Birth Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of Birth")
                        .font(.headline)
                    DatePicker("", selection: $birthDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .frame(maxHeight: 180)
                }
                
                // Birth Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Birth Time")
                        .font(.headline)
                    DatePicker("", selection: $birthTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .frame(maxHeight: 120)
                        .onChange(of: birthTime) { _, _ in
                            hasInteractedWithTimePicker = true
                        }
                    
                    Text("If you're unsure of your birth time, midnight will be used for chart calculation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Birth Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("City of Birth")
                        .font(.headline)
                    TextField("e.g., New York, NY", text: $birthCity)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.location)
                }
                
                // Privacy Notice
                Button(action: { showingPrivacyInfo = true }) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.green)
                        Text("Your birth data is private")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                    }
                }
                .sheet(isPresented: $showingPrivacyInfo) {
                    PrivacyInfoView()
                }
                
                Spacer(minLength: 32)
                
                Button(action: {
                    guard !name.isEmpty, !birthCity.isEmpty else { return }
                    
                    isComputing = true
                    
                    // If user never touched the time picker, default to midnight (nil)
                    let time = hasInteractedWithTimePicker ? birthTime : nil
                    
                    Task {
                        do {
                            let result = try await GeocodingService.shared.geocode(city: birthCity)
                            onComplete(name, birthDate, time, result.lat, result.lng, result.city)
                        } catch {
                            // Fallback to raw city name and approximate coordinates if geocoding fails
                            onComplete(name, birthDate, time, 0, 0, birthCity)
                        }
                        isComputing = false
                    }
                }) {
                    if isComputing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Compute My Chart")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(name.isEmpty || birthCity.isEmpty ? Color.gray : ThemeService.shared.accentColor)
                .cornerRadius(14)
                .disabled(name.isEmpty || birthCity.isEmpty || isComputing)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Onboarding Complete

struct OnboardingCompleteView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You're All Set")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your astrological profile has been computed and stored securely on this device.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onStart) {
                Text("Begin Tonight")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ThemeService.shared.accentColor)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Privacy Info

struct PrivacyInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Data Privacy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your birth data (date, time, and location) is stored exclusively on this device. It is never uploaded to our servers, shared with third parties, or used for analytics.")
                        .font(.body)
                    
                    Text("What we store locally:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Birth date, time, and coordinates", systemImage: "lock.fill")
                        Label("Natal chart and base score", systemImage: "lock.fill")
                        Label("Saved sound combinations", systemImage: "lock.fill")
                        Label("Session history", systemImage: "lock.fill")
                    }
                    .foregroundColor(.secondary)
                    
                    Text("What leaves your device:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Anonymous user ID for authentication", systemImage: "person.badge.key")
                        Label("Your nightly intention text (for affirmation generation)", systemImage: "bubble.left.fill")
                        Label("Purchase events for subscription validation", systemImage: "creditcard.fill")
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Onboarding Profile Data

struct OnboardingProfileData {
    var name: String = ""
    var birthDate: Date = Date()
    var birthTime: Date? = nil
    var birthLat: Double = 0
    var birthLng: Double = 0
    var birthCity: String = ""
    var currentLat: Double = 0
    var currentLng: Double = 0
    var currentCity: String = ""
    var useCurrentLocationForTransits: Bool = false
}
