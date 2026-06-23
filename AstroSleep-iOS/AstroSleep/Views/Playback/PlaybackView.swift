import SwiftUI

// MARK: - Playback View
/// Full-screen playback with layer visualization and controls.
struct PlaybackView: View {
    let combo: Combo
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var audioService: AudioService
    @EnvironmentObject var revenueCat: RevenueCatService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingLayerPanel = false
    @State private var showingSleepTimer = false
    @State private var selectedTimer: Int = 60
    @State private var showingSaveDialog = false
    @State private var comboName = ""
    @State private var showingStopConfirm = false
    
    let timerOptions = [30, 60, 90, 120]
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: {
                        audioService.pause()
                        appState.currentScreen = .main
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text(combo.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: { showingSleepTimer = true }) {
                        Image(systemName: "timer")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Main Visual
                Spacer()
                
                VStack(spacing: 24) {
                    // Dominant Element Symbol
                    if let dominantElement = combo.chartSnapshot?.dominantElement {
                        elementSymbol(dominantElement)
                    }
                    
                    // Layer Waveforms
                    layerVisualization
                    
                    // Playback Status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(audioService.isPlaying ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(audioService.isPlaying ? "Playing" : "Paused")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Controls
                VStack(spacing: 20) {
                    // Master Volume
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.secondary)
                        
                        Slider(value: Binding(
                            get: { audioService.masterVolume },
                            set: { audioService.setMasterVolume($0) }
                        ), in: 0...1)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Transport Controls
                    HStack(spacing: 40) {
                        Button(action: { showingStopConfirm = true }) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            if audioService.isPlaying {
                                audioService.pause()
                            } else {
                                audioService.resume()
                            }
                        }) {
                            Image(systemName: audioService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 72))
                                .foregroundColor(ThemeService.shared.accentColor)
                        }
                        
                        Button(action: { showingLayerPanel = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 28))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Save Button
                    Button(action: { showingSaveDialog = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save This Combo")
                        }
                        .font(.subheadline)
                        .foregroundColor(ThemeService.shared.accentColor)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            Task {
                try? await audioService.loadCombo(combo)
                audioService.play()
            }
        }
        .onDisappear {
            // Log session if played
            if let duration = audioService.currentSessionDuration,
               duration > 60 {
                let log = SessionLog(
                    date: Date(),
                    intention: appState.cachedAffirmation ?? "",
                    affirmationScript: appState.cachedAffirmation ?? "",
                    comboId: combo.id,
                    durationMinutes: Int(duration / 60),
                    timerFired: false,
                    tier: revenueCat.currentTier,
                    moonPhase: combo.chartSnapshot?.moonPhase ?? .newMoon,
                    layerCount: combo.layers.count
                )
                try? StorageService.shared.saveSessionLog(log)
            }
            audioService.resetSession()
        }
        .sheet(isPresented: $showingLayerPanel) {
            LayerDetailPanel(combo: combo)
        }
        .sheet(isPresented: $showingSleepTimer) {
            SleepTimerSheet(
                selectedTimer: $selectedTimer,
                timerOptions: timerOptions,
                onConfirm: {
                    audioService.setSleepTimer(minutes: selectedTimer)
                    showingSleepTimer = false
                }
            )
        }
        .alert("Save Combo", isPresented: $showingSaveDialog) {
            TextField("Combo name", text: $comboName)
            Button("Save", action: saveCombo)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Give your combo a name to save it to your library.")
        }
        .alert("End Session?", isPresented: $showingStopConfirm) {
            Button("End", role: .destructive) {
                audioService.stopAll()
                appState.currentScreen = .main
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will stop all sounds and end your session.")
        }
    }
    
    // MARK: - Element Symbol
    private func elementSymbol(_ element: Element) -> some View {
        ZStack {
            Circle()
                .fill(element.color.opacity(0.2))
                .frame(width: 120, height: 120)
            
            Image(systemName: element.icon)
                .font(.system(size: 48))
                .foregroundColor(element.color)
        }
    }
    
    // MARK: - Layer Visualization
    private var layerVisualization: some View {
        VStack(spacing: 4) {
            ForEach(combo.layers) { layer in
                if let sound = SoundLibrary.shared.sounds.first(where: { $0.id == layer.soundId }) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(sound.elementScores.dominant().color.opacity(0.6))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: audioService.isPlaying)
                    }
                }
            }
        }
        .padding(.horizontal, 40)
        .frame(height: 60)
    }
    
    private func saveCombo() {
        var updatedCombo = combo
        updatedCombo.name = comboName.isEmpty ? combo.name : comboName
        updatedCombo.source = .user
        
        // Check tier limit
        let existingCombos = StorageService.shared.loadCombos()
        let maxPlaylists = revenueCat.currentTier.maxPlaylists
        
        if existingCombos.count >= maxPlaylists && maxPlaylists != Int.max {
            appState.paywallTrigger = "save_combo"
            appState.showPaywall = true
            return
        }
        
        do {
            try StorageService.shared.saveCombo(updatedCombo)
            appState.errorMessage = "Combo saved!"
        } catch {
            appState.errorMessage = "Failed to save combo"
        }
    }
    
}

// MARK: - Layer Detail Panel

struct LayerDetailPanel: View {
    let combo: Combo
    @EnvironmentObject var audioService: AudioService
    @EnvironmentObject var revenueCat: RevenueCatService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(combo.layers) { layer in
                    if let sound = SoundLibrary.shared.sounds.first(where: { $0.id == layer.soundId }) {
                        LayerControlRow(
                            sound: sound,
                            layer: layer,
                            canEditSpeed: true,
                            canEditEQ: true,
                            canToggleOscillation: true
                        )
                    }
                }
                
                // Affirmation Layer
                Section("Affirmation") {
                    AffirmationControlRow(
                        layer: combo.affirmationLayer,
                        canEditSpeed: true
                    )
                }
            }
            .navigationTitle("Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct LayerControlRow: View {
    let sound: Sound
    let layer: AmbientLayer
    let canEditSpeed: Bool
    let canEditEQ: Bool
    let canToggleOscillation: Bool
    
    @State private var volume: Double
    @State private var showingEQ = false
    @State private var showingSpeed = false
    
    init(sound: Sound, layer: AmbientLayer, canEditSpeed: Bool, canEditEQ: Bool, canToggleOscillation: Bool) {
        self.sound = sound
        self.layer = layer
        self.canEditSpeed = canEditSpeed
        self.canEditEQ = canEditEQ
        self.canToggleOscillation = canToggleOscillation
        _volume = State(initialValue: layer.volume)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(sound.elementScores.dominant().color)
                    .frame(width: 10, height: 10)
                
                Text(sound.name)
                    .font(.headline)
                
                Spacer()
                
                if let osc = layer.oscillation, osc.enabled {
                    Image(systemName: "waveform")
                        .foregroundColor(ThemeService.shared.accentColor)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $volume, in: 0...1) { _ in
                    AudioService.shared.setLayerVolume(layerId: layer.id, volume: volume)
                }
                
                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
            
            HStack(spacing: 16) {
                if canEditEQ {
                    Button("EQ") { showingEQ = true }
                        .font(.caption)
                        .foregroundColor(ThemeService.shared.accentColor)
                }
                
                if canEditSpeed {
                    Button("Speed") { showingSpeed = true }
                        .font(.caption)
                        .foregroundColor(ThemeService.shared.accentColor)
                }
                
                if canToggleOscillation {
                    Toggle("LFO", isOn: .constant(layer.oscillation?.enabled ?? false))
                        .font(.caption)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEQ) {
            EQSheet(layer: layer)
        }
        .sheet(isPresented: $showingSpeed) {
            SpeedSheet(layer: layer)
        }
    }
}

struct AffirmationControlRow: View {
    let layer: AffirmationLayer
    let canEditSpeed: Bool
    @State private var volume: Double
    
    init(layer: AffirmationLayer, canEditSpeed: Bool) {
        self.layer = layer
        self.canEditSpeed = canEditSpeed
        _volume = State(initialValue: layer.volume)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(ThemeService.shared.accentColor)
                
                Text("Affirmation")
                    .font(.headline)
                
                Spacer()
                
                Text(layer.voiceId.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $volume, in: 0.02...0.20) { _ in
                    // Update affirmation volume
                }
                
                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
            
            if canEditSpeed {
                HStack {
                    Text("Speed: \(String(format: "%.2f", layer.playbackSpeed))x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - EQ Sheet

struct EQSheet: View {
    let layer: AmbientLayer
    @Environment(\.dismiss) private var dismiss
    @State private var bass: Double
    @State private var mid: Double
    @State private var treble: Double
    
    init(layer: AmbientLayer) {
        self.layer = layer
        _bass = State(initialValue: layer.eq.bass)
        _mid = State(initialValue: layer.eq.mid)
        _treble = State(initialValue: layer.eq.treble)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Equalizer") {
                    VStack(alignment: .leading) {
                        Text("Bass")
                            .font(.caption)
                        Slider(value: $bass, in: 0...1) { _ in
                            updateEQ()
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Mid")
                            .font(.caption)
                        Slider(value: $mid, in: 0...1) { _ in
                            updateEQ()
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Treble")
                            .font(.caption)
                        Slider(value: $treble, in: 0...1) { _ in
                            updateEQ()
                        }
                    }
                }
                
                Button("Reset") {
                    bass = 0.5
                    mid = 0.5
                    treble = 0.5
                    updateEQ()
                }
            }
            .navigationTitle("EQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func updateEQ() {
        let profile = EQProfile(bass: bass, mid: mid, treble: treble)
        AudioService.shared.updateEQ(layerId: layer.id, profile: profile)
    }
}

// MARK: - Speed Sheet

struct SpeedSheet: View {
    let layer: AmbientLayer
    @Environment(\.dismiss) private var dismiss
    @State private var speed: Double
    
    init(layer: AmbientLayer) {
        self.layer = layer
        _speed = State(initialValue: layer.playbackSpeed)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Playback Speed") {
                    Slider(value: $speed, in: 0.5...2.0, step: 0.05) { _ in
                        AudioService.shared.setLayerSpeed(layerId: layer.id, speed: speed)
                    }
                    
                    Text("\(String(format: "%.2f", speed))x")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Button("Reset to 1.0x") {
                    speed = 1.0
                    AudioService.shared.setLayerSpeed(layerId: layer.id, speed: 1.0)
                }
            }
            .navigationTitle("Speed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Sleep Timer Sheet

struct SleepTimerSheet: View {
    @Binding var selectedTimer: Int
    let timerOptions: [Int]
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Sleep Timer") {
                    ForEach(timerOptions, id: \.self) { minutes in
                        Button(action: {
                            selectedTimer = minutes
                        }) {
                            HStack {
                                Text("\(minutes) minutes")
                                Spacer()
                                if selectedTimer == minutes {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(ThemeService.shared.accentColor)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        selectedTimer = 0
                    }) {
                        HStack {
                            Text("Off")
                            Spacer()
                            if selectedTimer == 0 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ThemeService.shared.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Set") {
                        onConfirm()
                    }
                }
            }
        }
    }
}
