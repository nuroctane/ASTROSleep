import SwiftUI

// MARK: - Combo Builder View
struct ComboBuilderView: View {
    let existingCombo: Combo?
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var audioService: AudioService
    @EnvironmentObject var revenueCat: RevenueCatService
    @Environment(\.dismiss) private var dismiss
    
    @State private var combo: Combo
    @State private var showingSoundPicker = false
    @State private var showingAutoGenerateAlert = false
    @State private var isPreviewing = false
    @State private var showingSaveSheet = false
    @State private var comboName = ""
    
    init(existingCombo: Combo? = nil) {
        self.existingCombo = existingCombo
        _combo = State(initialValue: existingCombo ?? Combo(
            id: UUID().uuidString,
            name: "New Combo",
            createdAt: Date(),
            source: .user,
            chartSnapshot: nil,
            layers: [],
            affirmationLayer: .default(),
            isReadOnly: false
        ))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Layers Section
                Section {
                    ForEach(combo.layers) { layer in
                        if let sound = SoundLibrary.shared.sounds.first(where: { $0.id == layer.soundId }) {
                            LayerEditRow(
                                sound: sound,
                                layer: layer,
                                canEditSpeed: true,
                                canEditOscillation: true,
                                onDelete: { deleteLayer(layer) },
                                onUpdate: { updatedLayer in
                                    updateLayer(updatedLayer)
                                }
                            )
                        }
                    }
                    .onDelete(perform: deleteLayers)
                    .onMove(perform: moveLayers)
                } header: {
                    Text("Ambient Layers (\(combo.layers.count)/\(revenueCat.currentTier.maxLayers))")
                }
                
                // Add Sound Button
                if combo.layers.count < revenueCat.currentTier.maxLayers {
                    Button(action: { showingSoundPicker = true }) {
                        Label("Add Sound", systemImage: "plus.circle.fill")
                            .foregroundColor(ThemeService.shared.accentColor)
                    }
                }
                
                // Affirmation Section
                Section("Affirmation") {
                    AffirmationEditRow(
                        layer: combo.affirmationLayer,
                        canEditSpeed: true
                    )
                }
                
                // Actions
                Section {
                    Button(action: { previewCombo() }) {
                        Label(isPreviewing ? "Stop Preview" : "Preview (30s)",
                              systemImage: isPreviewing ? "stop.fill" : "play.fill")
                    }
                    .foregroundColor(ThemeService.shared.accentColor)
                    
                    Button(action: { showingAutoGenerateAlert = true }) {
                        Label("Auto-Generate", systemImage: "sparkles")
                    }
                    .foregroundColor(ThemeService.shared.accentColor)
                    // Transit scoring is free for all tiers
                    
                    Button(action: { showingSaveSheet = true }) {
                        Label("Save Combo", systemImage: "square.and.arrow.down")
                    }
                    .foregroundColor(ThemeService.shared.accentColor)
                }
            }
            .navigationTitle("Combo Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingSoundPicker) {
                SoundPickerView(onSelect: { sound in
                    addSound(sound)
                    showingSoundPicker = false
                })
            }
            .alert("Auto-Generate Combo?", isPresented: $showingAutoGenerateAlert) {
                Button("Generate", action: autoGenerate)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will replace all layers with AI-scored sounds based on tonight's chart.")
            }
            .sheet(isPresented: $showingSaveSheet) {
                SaveComboSheet(
                    name: $comboName,
                    onSave: saveCombo,
                    onCancel: { showingSaveSheet = false }
                )
            }
        }
    }
    
    private func addSound(_ sound: Sound) {
        guard combo.layers.count < revenueCat.currentTier.maxLayers else { return }
        
        let layer = AmbientLayer(
            soundId: sound.id,
            volume: 0.5,
            playbackSpeed: 1.0,
            eq: EQProfile.profile(forRegister: sound.tags.register),
            oscillation: nil
        )
        
        combo.layers.append(layer)
    }
    
    private func deleteLayer(_ layer: AmbientLayer) {
        combo.layers.removeAll { $0.id == layer.id }
    }
    
    private func deleteLayers(at offsets: IndexSet) {
        combo.layers.remove(atOffsets: offsets)
    }
    
    private func moveLayers(from source: IndexSet, to destination: Int) {
        combo.layers.move(fromOffsets: source, toOffset: destination)
    }
    
    private func updateLayer(_ layer: AmbientLayer) {
        if let index = combo.layers.firstIndex(where: { $0.id == layer.id }) {
            combo.layers[index] = layer
        }
    }
    
    private func previewCombo() {
        if isPreviewing {
            audioService.stopAll()
            isPreviewing = false
        } else {
            Task {
                try? await audioService.loadCombo(combo)
                audioService.play()
                isPreviewing = true
                
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                    if isPreviewing {
                        audioService.stopAll()
                        isPreviewing = false
                    }
                }
            }
        }
    }
    
    private func autoGenerate() {
        let newCombo = appState.autoGenerateCombo(
            intention: "",
            tier: revenueCat.currentTier
        )
        combo.layers = newCombo.layers
        combo.chartSnapshot = newCombo.chartSnapshot
    }
    
    private func saveCombo() {
        guard !comboName.isEmpty else { return }
        
        var finalCombo = combo
        finalCombo.name = comboName
        finalCombo.source = .user
        
        // Check tier limit
        let existing = StorageService.shared.loadCombos()
        if existing.count >= revenueCat.currentTier.maxPlaylists && revenueCat.currentTier.maxPlaylists != Int.max {
            appState.paywallTrigger = "save_playlist"
            appState.showPaywall = true
            return
        }
        
        do {
            try StorageService.shared.saveCombo(finalCombo)
            appState.errorMessage = "Combo saved successfully"
            showingSaveSheet = false
        } catch {
            appState.errorMessage = "Failed to save combo"
        }
    }
}

// MARK: - Affirmation Edit Row

struct AffirmationEditRow: View {
    let layer: AffirmationLayer
    let canEditSpeed: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Slider(value: .constant(layer.volume), in: 0...1)
                    .disabled(true)
                
                Text("\(Int(layer.volume * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 30)
            }
            
            if canEditSpeed {
                Text("Speed: \(String(format: "%.2f", layer.playbackSpeed))x")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Layer Edit Row

struct LayerEditRow: View {
    let sound: Sound
    @State var layer: AmbientLayer
    let canEditSpeed: Bool
    let canEditOscillation: Bool
    let onDelete: () -> Void
    let onUpdate: (AmbientLayer) -> Void
    
    @State private var showingEQ = false
    @State private var showingSpeed = false
    @State private var showingOscillation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                elementBadge(sound.elementScores.dominant())
                
                Text(sound.name)
                    .font(.headline)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.6))
                }
            }
            
            HStack {
                Image(systemName: "speaker.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { layer.volume },
                    set: {
                        layer.volume = $0
                        onUpdate(layer)
                    }
                ), in: 0...1)
                
                Text("\(Int(layer.volume * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 30)
            }
            
            HStack(spacing: 12) {
                Button("EQ") { showingEQ = true }
                    .font(.caption)
                    .foregroundColor(ThemeService.shared.accentColor)
                
                if canEditSpeed {
                    Button("Speed") { showingSpeed = true }
                        .font(.caption)
                        .foregroundColor(ThemeService.shared.accentColor)
                }
                
                if canEditOscillation {
                    Button("LFO") { showingOscillation = true }
                        .font(.caption)
                        .foregroundColor(ThemeService.shared.accentColor)
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
    
    private func elementBadge(_ element: Element) -> some View {
        Circle()
            .fill(element.color)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Sound Picker

struct SoundPickerView: View {
    let onSelect: (Sound) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredSounds: [Sound] {
        if searchText.isEmpty {
            return SoundLibrary.shared.sounds
        }
        return SoundLibrary.shared.sounds.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredSounds) { sound in
                Button(action: {
                    onSelect(sound)
                }) {
                    HStack {
                        elementBadge(sound.elementScores.dominant())
                        Text(sound.name)
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundColor(ThemeService.shared.accentColor)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search sounds...")
            .navigationTitle("Add Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func elementBadge(_ element: Element) -> some View {
        Circle()
            .fill(element.color)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Save Combo Sheet

struct SaveComboSheet: View {
    @Binding var name: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Combo name", text: $name)
                        .autocapitalization(.words)
                }
                
                Section {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(name.isEmpty)
                    
                    Button("Cancel", role: .cancel) {
                        onCancel()
                    }
                }
            }
            .navigationTitle("Save Combo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
