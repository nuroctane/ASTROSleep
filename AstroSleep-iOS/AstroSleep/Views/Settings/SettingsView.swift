import SwiftUI
import AVFoundation

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var revenueCat: RevenueCatService
    @EnvironmentObject var notificationService: NotificationService
    
    @State private var showingDeleteConfirm = false
    @State private var showingSignOutConfirm = false
    @State private var showingRecomputeAlert = false
    @State private var showingPaywall = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section("Profile") {
                    NavigationLink("Name & Birth Data") {
                        ProfileEditView()
                    }
                }
                
                // Location Section
                Section("Location") {
                    Toggle(
                        "Use Current Location for Transits",
                        isOn: Binding(
                            get: { appState.profile?.useCurrentLocationForTransits ?? false },
                            set: { newValue in
                                if var profile = appState.profile {
                                    profile.useCurrentLocationForTransits = newValue
                                    try? StorageService.shared.saveProfile(profile)
                                    appState.profile = profile
                                    appState.computeNightlyScore()
                                }
                            }
                        )
                    )
                    
                    Text("When enabled, AstroSleep uses your current geographic location to compute house placements and angular emphasis for tonight's transits. This makes transit scoring more accurate if you are traveling or living away from your birthplace.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if appState.profile?.useCurrentLocationForTransits == true {
                        NavigationLink("Current Location") {
                            CurrentLocationEditView()
                        }
                    }
                }
                
                // Subscription Section
                Section("Subscription") {
                    HStack {
                        Text("Current Plan")
                        Spacer()
                        Text(revenueCat.currentTier.displayName)
                            .foregroundColor(.secondary)
                        if revenueCat.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    Button("Manage Subscription") {
                        showingPaywall = true
                    }
                    .foregroundColor(ThemeService.shared.accentColor)
                    
                    Button("Restore Purchases") {
                        Task {
                            _ = try? await revenueCat.restorePurchases()
                        }
                    }
                    .foregroundColor(ThemeService.shared.accentColor)
                }
                
                // Appearance Section
                Section("Appearance") {
                    NavigationLink("Appearance Mode") {
                        AppearanceModeView()
                    }
                    
                    NavigationLink("Accent Color") {
                        AccentColorPickerView()
                    }
                    
                    NavigationLink("Background Color") {
                        BackgroundColorPickerView()
                    }
                    
                    Button("Background Image") {
                        showingImagePicker = true
                    }
                    .foregroundColor(ThemeService.shared.accentColor)
                    
                    if ThemeService.shared.backgroundImage != nil {
                        Button("Remove Background Image", role: .destructive) {
                            ThemeService.shared.backgroundImage = nil
                            ThemeService.shared.saveTheme(ThemeConfig(
                                accentColorHex: ThemeService.shared.accentColor.toHex() ?? "5856D6",
                                backgroundColorHex: ThemeService.shared.backgroundColor.toHex(),
                                backgroundImagePath: nil,
                                useSystemAppearance: ThemeService.shared.useSystemAppearance
                            ))
                        }
                    }
                    
                    Button("Reset to Default") {
                        ThemeService.shared.resetToDefault()
                    }
                    .foregroundColor(.secondary)
                }
                
                // Audio Section
                Section("Audio") {
                    NavigationLink("Background Audio") {
                        AudioSettingsView()
                    }
                    
                    NavigationLink("Sleep Timer Default") {
                        SleepTimerSettingsView()
                    }
                }
                
                // Affirmation Section
                Section("Affirmation") {
                    NavigationLink("Voice & Speed") {
                        AffirmationSettingsView()
                    }
                }
                
                // Notifications Section
                Section("Notifications") {
                    NavigationLink("Bedtime Reminder") {
                        NotificationSettingsView()
                    }
                }
                
                // Privacy Section
                Section("Privacy") {
                    Text("Your birth data is stored only on this device and never uploaded.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Delete All My Data", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    if let privacyURL = URL(string: "https://astrosleep.app/privacy") {
                        Link("Privacy Policy", destination: privacyURL)
                    }
                    if let termsURL = URL(string: "https://astrosleep.app/terms") {
                        Link("Terms of Service", destination: termsURL)
                    }
                }
                
                // Account Section
                if authService.isAuthenticated {
                    Section {
                        Button("Sign Out", role: .destructive) {
                            showingSignOutConfirm = true
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PaywallView(triggerFeature: "manage_subscription")
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your birth data, combos, and session history from this device. This action cannot be undone.")
            }
            .alert("Sign Out?", isPresented: $showingSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    private func deleteAllData() {
        do {
            try StorageService.shared.deleteAllData()
            appState.profile = nil
            appState.currentScreen = .onboarding
        } catch {
            appState.errorMessage = "Failed to delete data"
        }
    }
}

// MARK: - Profile Edit

struct ProfileEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var hasBirthTime = false
    @State private var birthTime = Date()
    @State private var birthCity = ""
    @State private var isSaving = false
    @State private var saveError: String?
    
    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name", text: $name)
            }
            
            Section("Birth Date") {
                DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
            }
            
            Section("Birth Time") {
                Toggle("I know my birth time", isOn: $hasBirthTime)
                if hasBirthTime {
                    DatePicker("Birth Time", selection: $birthTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section("Birth Location") {
                TextField("City of Birth", text: $birthCity)
                    .textContentType(.location)
            }
            
            Section {
                Button(action: saveProfile) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save & Recompute Chart")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty || birthCity.isEmpty ? Color.gray : ThemeService.shared.accentColor)
                    .cornerRadius(10)
                }
                .disabled(name.isEmpty || birthCity.isEmpty || isSaving)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            if let error = saveError {
                Section {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let profile = appState.profile {
                name = profile.name
                birthDate = profile.birthDate
                hasBirthTime = profile.birthTime != nil
                birthTime = profile.birthTime ?? Date()
                birthCity = profile.birthCity
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        saveError = nil
        
        let time = hasBirthTime ? birthTime : nil
        
        Task {
            do {
                try await appState.updateBirthData(
                    name: name,
                    birthDate: birthDate,
                    birthTime: time,
                    birthCity: birthCity
                )
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch let error as GeocodingError {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = "Failed to update profile. Please try again."
                }
            }
        }
    }
}

// MARK: - Audio Settings

struct AudioSettingsView: View {
    @State private var backgroundAudio = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Background Audio", isOn: $backgroundAudio)
                
                Text("Allow sounds to continue playing when the app is in the background or when the screen is locked.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Audio")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sleep Timer Settings

struct SleepTimerSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var defaultTimer = 60
    
    let options = [30, 60, 90, 120]
    
    var body: some View {
        Form {
            Section("Default Sleep Timer") {
                Picker("Timer", selection: $defaultTimer) {
                    ForEach(options, id: \.self) { minutes in
                        Text("\(minutes) minutes")
                            .tag(minutes)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            }
            
            Section {
                Button("Save Default") {
                    Task {
                        try? StorageService.shared.updateProfile { profile in
                            profile.sleepTimerDefault = defaultTimer
                        }
                        await MainActor.run {
                            appState.loadProfile()
                        }
                    }
                }
            }
        }
        .navigationTitle("Sleep Timer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            defaultTimer = appState.profile?.sleepTimerDefault ?? 60
        }
    }
}

// MARK: - Affirmation Settings

struct AffirmationSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var revenueCat: RevenueCatService
    
    @State private var selectedVoice = "com.apple.ttsbundle.SiriFemale_en-US"
    @State private var globalSpeed = 1.0
    @State private var globalPitch = 0.0
    @State private var volumeOffset = 0.10
    
    /// Available iOS on-device voices (Siri + enhanced quality voices)
    private var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") && ($0.quality == .enhanced || $0.name.lowercased().contains("siri")) }
            .sorted { $0.name < $1.name }
    }
    
    var body: some View {
        Form {
            Section("On-Device Voice") {
                if availableVoices.isEmpty {
                    Text("Loading voices...")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(availableVoices, id: \.identifier) { voice in
                            let quality = voice.quality == .enhanced ? "Enhanced" : "Default"
                            Text("\(voice.name) · \(quality)").tag(voice.identifier)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                if !revenueCat.currentTier.hasCustomVoice {
                    Text("Custom voice recording available on Pro Lifetime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Playback Speed") {
                Slider(value: $globalSpeed, in: 0.5...1.5, step: 0.05)
                Text("\(String(format: "%.2f", globalSpeed))x")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            Section("Pitch Shift") {
                Slider(value: $globalPitch, in: -6...6, step: 0.5)
                Text("\(globalPitch >= 0 ? "+" : "")\(String(format: "%.1f", globalPitch)) semitones")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            Section("Volume") {
                Slider(value: $volumeOffset, in: 0.02...0.20, step: 0.01)
                Text("\(Int(volumeOffset * 100))%")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            Section {
                Button("Save") {
                    Task {
                        try? StorageService.shared.updateProfile { profile in
                            profile.selectedVoiceId = selectedVoice
                            profile.globalAffirmationSpeed = globalSpeed
                            profile.globalAffirmationPitch = globalPitch
                        }
                        await MainActor.run {
                            appState.loadProfile()
                        }
                    }
                }
            }
        }
        .navigationTitle("Voice & Speed")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedVoice = appState.profile?.selectedVoiceId ?? "com.apple.ttsbundle.SiriFemale_en-US"
            globalSpeed = appState.profile?.globalAffirmationSpeed ?? 1.0
            globalPitch = appState.profile?.globalAffirmationPitch ?? 0.0
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var appState: AppState
    
    @State private var enabled = false
    @State private var reminderTime = Date()
    
    var body: some View {
        Form {
            Section {
                Toggle("Bedtime Reminder", isOn: $enabled)
                    .onChange(of: enabled) { oldValue, newValue in
                        if newValue {
                            Task {
                                let granted = await notificationService.requestAuthorization()
                                if granted {
                                    notificationService.scheduleBedtimeReminder(at: reminderTime)
                                }
                            }
                        } else {
                            notificationService.cancelBedtimeReminder()
                        }
                    }
            }
            
            if enabled {
                Section("Reminder Time") {
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .frame(height: 120)
                        .onChange(of: reminderTime) { oldValue, newValue in
                            notificationService.scheduleBedtimeReminder(at: newValue)
                        }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Current Location Edit

struct CurrentLocationEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentCity: String = ""
    @State private var isSaving = false
    @State private var saveError: String?
    
    var body: some View {
        Form {
            Section("Current Location") {
                TextField("City (e.g., Los Angeles, CA)", text: $currentCity)
                    .textContentType(.location)
                
                Text("Enter your current city for accurate transit house placement. Coordinates are looked up automatically and used only on-device for astrological computation.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button(action: saveLocation) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save & Recompute Transits")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentCity.isEmpty ? Color.gray : ThemeService.shared.accentColor)
                    .cornerRadius(10)
                }
                .disabled(currentCity.isEmpty || isSaving)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            if let error = saveError {
                Section {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Current Location")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let profile = appState.profile {
                currentCity = profile.currentCity
            }
        }
    }
    
    private func saveLocation() {
        isSaving = true
        saveError = nil
        
        Task {
            do {
                let result = try await GeocodingService.shared.geocode(city: currentCity)
                
                try StorageService.shared.updateProfile { profile in
                    profile.currentCity = result.city
                    profile.currentLat = result.lat
                    profile.currentLng = result.lng
                }
                
                await MainActor.run {
                    appState.loadProfile()
                    appState.computeNightlyScore()
                    isSaving = false
                    dismiss()
                }
            } catch let error as GeocodingError {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = "Failed to update location. Please try again."
                }
            }
        }
    }
}

// MARK: - Appearance Mode

struct AppearanceModeView: View {
    @State private var useSystem = ThemeService.shared.useSystemAppearance
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $useSystem) {
                    Text("System").tag(true)
                    Text("Light").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: useSystem) { oldValue, newValue in
                    ThemeService.shared.useSystemAppearance = newValue
                    ThemeService.shared.saveTheme(ThemeService.shared.currentConfig)
                }
            }
        }
        .navigationTitle("Appearance Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Accent Color Picker

struct AccentColorPickerView: View {
    @State private var selectedHex: String = ThemeService.shared.currentConfig.accentColorHex
    @Environment(\.dismiss) private var dismiss
    
    let presetColors: [(name: String, hex: String)] = [
        ("Indigo", "5856D6"),
        ("Pink", "FF2D55"),
        ("Orange", "FF9500"),
        ("Green", "34C759"),
        ("Teal", "5AC8FA"),
        ("Purple", "AF52DE"),
        ("Red", "FF3B30"),
        ("Blue", "007AFF")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview
                VStack(spacing: 12) {
                    Text("Preview")
                        .font(.headline)
                    HStack(spacing: 16) {
                        Button("Sample") {}
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: selectedHex) ?? .indigo)
                        Toggle("", isOn: .constant(true))
                            .tint(Color(hex: selectedHex) ?? .indigo)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                
                // Presets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Presets")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                        ForEach(presetColors, id: \.hex) { preset in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: preset.hex) ?? .indigo)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedHex == preset.hex ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                Text(preset.name)
                                    .font(.caption)
                            }
                            .onTapGesture {
                                selectedHex = preset.hex
                                apply()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func apply() {
        var config = ThemeService.shared.currentConfig
        config.accentColorHex = selectedHex
        ThemeService.shared.saveTheme(config)
        ThemeService.shared.updateProfileTheme(config)
    }
}

// MARK: - Background Color Picker

struct BackgroundColorPickerView: View {
    @State private var selectedHex: String? = ThemeService.shared.currentConfig.backgroundColorHex
    @Environment(\.dismiss) private var dismiss
    
    let presetColors: [(name: String, hex: String)] = [
        ("Default", ""),
        ("Midnight", "1C1C1E"),
        ("Deep Blue", "0A192F"),
        ("Forest", "1A2F1A"),
        ("Warm", "2C1B18"),
        ("Slate", "1E293B"),
        ("Rose", "2C1818"),
        ("Charcoal", "121212")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview
                VStack(spacing: 12) {
                    Text("Preview")
                        .font(.headline)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(selectedHex.flatMap { Color(hex: $0) } ?? Color(.systemBackground))
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                }
                .padding(.horizontal)
                
                // Presets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Presets")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                        ForEach(presetColors, id: \.hex) { preset in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(preset.hex.isEmpty ? Color(.systemBackground) : (Color(hex: preset.hex) ?? .black))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedHex == preset.hex || (selectedHex == nil && preset.hex.isEmpty) ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                Text(preset.name)
                                    .font(.caption)
                            }
                            .onTapGesture {
                                selectedHex = preset.hex.isEmpty ? nil : preset.hex
                                apply()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .navigationTitle("Background Color")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func apply() {
        var config = ThemeService.shared.currentConfig
        config.backgroundColorHex = selectedHex
        ThemeService.shared.saveTheme(config)
        ThemeService.shared.updateProfileTheme(config)
    }
}
