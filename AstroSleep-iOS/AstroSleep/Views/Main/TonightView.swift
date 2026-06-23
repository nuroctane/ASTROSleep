import SwiftUI

// MARK: - Tonight's Screen (Home)
struct TonightView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var audioService: AudioService
    @EnvironmentObject var revenueCat: RevenueCatService
    
    @State private var intention = ""
    @State private var showingOfflineNotice = false
    @State private var generatedCombo: Combo?
    @State private var isGeneratingAffirmation = false
    @State private var moonPhase: MoonPhase = .newMoon
    
    private let maxIntentionLength = 280
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Moon Phase
                    moonPhaseSection
                    
                    // Recommendation
                    if let combo = generatedCombo ?? appState.activeCombo {
                        recommendationSection(combo: combo)
                    }
                    
                    // Intention Input
                    intentionSection
                    
                    // Begin Session Button
                    beginButton
                    
                    // Offline notice
                    if showingOfflineNotice {
                        offlineNotice
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("AstroSleep")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .onAppear {
                computeNightlyData()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            let hour = Calendar.current.component(.hour, from: Date())
            let greeting: String
            switch hour {
            case 0..<12: greeting = "Good morning"
            case 12..<17: greeting = "Good afternoon"
            default: greeting = "Good evening"
            }
            
            Text("\(greeting), \(appState.profile?.name ?? "there")")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Ready to direct your subconscious tonight?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
    
    // MARK: - Moon Phase
    private var moonPhaseSection: some View {
        HStack(spacing: 12) {
            Image(systemName: moonPhase.sfSymbolName)
                .font(.system(size: 32))
                .foregroundColor(ThemeService.shared.accentColor)
                .symbolRenderingMode(.multicolor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Tonight's Moon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(moonPhase.displayName)
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Recommendation
    private func recommendationSection(combo: Combo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tonight's Recommendation")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // Regenerate combo
                    generatedCombo = appState.autoGenerateCombo(
                        intention: intention.isEmpty ? "Sleep well" : intention,
                        tier: revenueCat.currentTier
                    )
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(ThemeService.shared.accentColor)
                }
            }
            
            // Combo preview card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(combo.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Element badges
                    HStack(spacing: 4) {
                        ForEach(combo.dominantElements.prefix(2), id: \.self) { element in
                            elementBadge(element)
                        }
                    }
                }
                
                // Layer preview
                HStack(spacing: 8) {
                    ForEach(combo.layers.prefix(3)) { layer in
                        if let sound = SoundLibrary.shared.sounds.first(where: { $0.id == layer.soundId }) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(sound.elementScores.dominant().color)
                                    .frame(width: 8, height: 8)
                                Text(sound.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                
                HStack {
                    Text("\(combo.layers.count) layer\(combo.layers.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if combo.source == .auto {
                        Label("Auto-generated", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(ThemeService.shared.accentColor)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .onTapGesture {
                appState.activeCombo = combo
            }
        }
    }
    
    // MARK: - Intention Input
    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What would you like to work on tonight?")
                .font(.headline)
            
            SmoothTextEditor(
                text: $intention,
                placeholder: "Tonight I intend to...",
                maxLength: maxIntentionLength
            )
        }
    }
    
    // MARK: - Begin Button
    private var beginButton: some View {
        Button(action: {
            Task {
                await beginSession()
            }
        }) {
            HStack {
                if isGeneratingAffirmation {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(showingOfflineNotice ? "Begin Without Affirmation" : "Begin Tonight's Session")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(ThemeService.shared.accentColor)
            .cornerRadius(14)
        }
        .disabled(isGeneratingAffirmation)
    }
    
    // MARK: - Offline Notice
    private var offlineNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
            Text("Offline — affirmation unavailable tonight")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helpers
    private func computeNightlyData() {
        appState.computeNightlyScore()
        moonPhase = appState.currentNightlyScore?.moonPhase ?? .newMoon
        
        // Pre-generate combo
        generatedCombo = appState.autoGenerateCombo(
            intention: "Sleep well",
            tier: revenueCat.currentTier
        )
    }
    
    private func beginSession() async {
        isGeneratingAffirmation = true
        defer { isGeneratingAffirmation = false }
        
        let combo = generatedCombo ?? appState.autoGenerateCombo(
            intention: intention,
            tier: revenueCat.currentTier
        )
        
        // Get affirmation
        let affirmation = await appState.getOrCreateAffirmation(intention: intention)
        
        if affirmation == nil {
            showingOfflineNotice = true
        }
        
        appState.activeCombo = combo
        
        // Navigate to playback
        withAnimation {
            appState.currentScreen = .playback(combo)
        }
    }
    
    private func elementBadge(_ element: Element) -> some View {
        Circle()
            .fill(element.color)
            .frame(width: 12, height: 12)
    }
}

// MARK: - Smooth Text Editor

struct SmoothTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let maxLength: Int
    
    @State private var isFocused = false
    @FocusState private var editorFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .focused($editorFocused)
                    .frame(minHeight: 80, maxHeight: 200)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? ThemeService.shared.accentColor : Color(.separator), lineWidth: isFocused ? 2 : 1)
                    )
                    .onChange(of: text) { oldValue, newValue in
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }
                    .onTapGesture {
                        isFocused = true
                    }
                
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(14)
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: editorFocused) { oldValue, newValue in
                isFocused = newValue
            }
            
            HStack {
                Text("\(text.count)/\(maxLength)")
                    .font(.caption)
                    .foregroundColor(text.count > maxLength ? .red : .secondary)
                
                Spacer()
            }
        }
    }
}
