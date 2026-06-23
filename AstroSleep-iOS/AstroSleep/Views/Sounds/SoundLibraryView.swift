import SwiftUI

// MARK: - Sound Library View
struct SoundLibraryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var audioService: AudioService
    @EnvironmentObject var revenueCat: RevenueCatService
    
    @State private var selectedElement: Element?
    @State private var showingNewOnly = false
    @State private var searchText = ""
    @State private var previewingSound: Sound?
    @State private var currentComboBuilder: Combo?
    @State private var showingComboBuilder = false
    @State private var showingFilterSheet = false
    @State private var activeTagFilters: [String: Set<String>] = [:]
    
    private var filteredSounds: [Sound] {
        var sounds = SoundLibrary.shared.sounds
        
        if let element = selectedElement {
            sounds = sounds.filter { $0.elementScores.dominant() == element }
        }
        
        if showingNewOnly {
            sounds = sounds.filter { $0.isNew }
        }
        
        if !searchText.isEmpty {
            sounds = sounds.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply tag dimension filters (AND across dimensions)
        for (dimension, values) in activeTagFilters where !values.isEmpty {
            sounds = sounds.filter { sound in
                let soundValue = soundValue(for: sound, dimension: dimension)
                return values.contains(soundValue)
            }
        }
        
        return sounds
    }
    
    private var activeFilterCount: Int {
        (selectedElement != nil ? 1 : 0) + activeTagFilters.values.filter { !$0.isEmpty }.count + (showingNewOnly ? 1 : 0)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Search and Filters
                    searchAndFilterSection
                    
                    // Result count
                    HStack {
                        Text("Showing \(filteredSounds.count) of \(SoundLibrary.shared.sounds.count) sounds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Active filter chips
                    if activeFilterCount > 0 {
                        activeFilterChips
                    }
                    
                    // Sound Grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                        ForEach(filteredSounds) { sound in
                            SoundCard(
                                sound: sound,
                                isPreviewing: previewingSound?.id == sound.id,
                                onPreview: { previewSound(sound) },
                                onAddToCombo: { addToCombo(sound) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Sound Library")
            .searchable(text: $searchText, prompt: "Search sounds...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilterSheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(ThemeService.shared.accentColor)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingComboBuilder) {
                if let combo = currentComboBuilder {
                    ComboBuilderView(existingCombo: combo)
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                SoundFilterSheet(
                    selectedElement: $selectedElement,
                    showingNewOnly: $showingNewOnly,
                    activeTagFilters: $activeTagFilters
                )
            }
        }
    }
    
    // MARK: - Search & Filter
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Element Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedElement == nil,
                        color: .primary
                    ) {
                        selectedElement = nil
                    }
                    
                    ForEach(Element.allCases) { element in
                        FilterChip(
                            title: element.rawValue,
                            isSelected: selectedElement == element,
                            color: element.color
                        ) {
                            selectedElement = element
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // New toggle
            Toggle("Show New Only", isOn: $showingNewOnly)
                .padding(.horizontal)
        }
    }
    
    private var activeFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if selectedElement != nil {
                    FilterPill(title: "Element: \(selectedElement!.rawValue)") {
                        selectedElement = nil
                    }
                }
                if showingNewOnly {
                    FilterPill(title: "New Only") {
                        showingNewOnly = false
                    }
                }
                for (dimension, values) in activeTagFilters where !values.isEmpty {
                    ForEach(Array(values), id: \.self) { value in
                        FilterPill(title: "\(dimension): \(value)") {
                            activeTagFilters[dimension]?.remove(value)
                            if activeTagFilters[dimension]?.isEmpty == true {
                                activeTagFilters.removeValue(forKey: dimension)
                            }
                        }
                    }
                }
                Button("Clear All") {
                    selectedElement = nil
                    showingNewOnly = false
                    activeTagFilters.removeAll()
                }
                .font(.caption)
                .foregroundColor(ThemeService.shared.accentColor)
            }
            .padding(.horizontal)
        }
    }
    
    private func previewSound(_ sound: Sound) {
        previewingSound = sound
        // In production: play 30-second preview
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
            previewingSound = nil
        }
    }
    
    private func addToCombo(_ sound: Sound) {
        // Create or open combo builder
        var combo = currentComboBuilder ?? appState.autoGenerateCombo(
            intention: "",
            tier: revenueCat.currentTier
        )
        
        // Check layer limit
        if combo.layers.count >= revenueCat.currentTier.maxLayers {
            appState.paywallTrigger = "add_layer"
            appState.showPaywall = true
            return
        }
        
        let newLayer = AmbientLayer(
            soundId: sound.id,
            volume: 0.5,
            playbackSpeed: 1.0,
            eq: .default,
            oscillation: nil
        )
        
        combo.layers.append(newLayer)
        currentComboBuilder = combo
        showingComboBuilder = true
    }
    
    private func soundValue(for sound: Sound, dimension: String) -> String {
        let tags = sound.tags
        switch dimension {
        case "domain": return tags.domain
        case "rhythm": return tags.rhythm
        case "register": return tags.register
        case "context": return tags.context
        case "weight": return tags.weight
        case "texture": return tags.texture
        case "motion": return tags.motion
        case "density": return tags.density
        case "temperature": return tags.temperature
        case "polarity": return tags.polarity
        case "celestial": return tags.celestial
        case "archetype": return tags.archetype
        default: return ""
        }
    }
}

// MARK: - Sound Card

struct SoundCard: View {
    let sound: Sound
    let isPreviewing: Bool
    let onPreview: () -> Void
    let onAddToCombo: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sound Icon Area
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 100)
                
                Image(systemName: soundIcon(sound.tags.domain))
                    .font(.system(size: 36))
                    .foregroundColor(sound.elementScores.dominant().color)
                
                if isPreviewing {
                    Image(systemName: "waveform")
                        .font(.title2)
                        .foregroundColor(ThemeService.shared.accentColor)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                if sound.isNew {
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(8)
                }
                
                if !sound.isDownloaded {
                    Image(systemName: "icloud.and.arrow.down")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(8)
                }
            }
            
            // Sound Info
            VStack(alignment: .leading, spacing: 4) {
                Text(sound.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                // Element score mini-bars
                HStack(spacing: 2) {
                    elementBar(value: sound.elementScores.fire, color: .orange)
                    elementBar(value: sound.elementScores.earth, color: .brown)
                    elementBar(value: sound.elementScores.air, color: .yellow)
                    elementBar(value: sound.elementScores.water, color: .blue)
                }
                .frame(height: 4)
                .padding(.vertical, 2)
                
                // Tag pills
                HStack(spacing: 4) {
                    ForEach(topTags(for: sound), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.secondary)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 4) {
                    Text(sound.tags.domain.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .contextMenu {
            Button(action: onPreview) {
                Label("Preview", systemImage: "play.fill")
            }
            Button(action: onAddToCombo) {
                Label("Add to Combo", systemImage: "plus")
            }
        }
    }
    
    private func elementBar(value: Double, color: Color) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.7))
                .frame(width: geo.size.width * CGFloat(value), height: geo.size.height)
        }
    }
    
    private func topTags(for sound: Sound) -> [String] {
        let tags = [
            (sound.tags.domain, 2.0),
            (sound.tags.rhythm, 1.5),
            (sound.tags.register, 1.5),
            (sound.tags.context, 1.5),
            (sound.tags.motion, 1.0),
            (sound.tags.temperature, 1.0)
        ]
        return tags.prefix(3).map { $0.0 }
    }
    
    private func soundIcon(_ domain: String) -> String {
        switch domain {
        case "water": return "drop.fill"
        case "air": return "wind"
        case "fire": return "flame.fill"
        case "earth": return "mountain.fill"
        case "mechanical": return "gearshape.fill"
        case "organic": return "leaf.fill"
        case "electrical": return "bolt.fill"
        case "cosmic": return "star.fill"
        default: return "waveform"
        }
    }
    
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.secondarySystemBackground))
                .cornerRadius(16)
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .foregroundColor(.primary)
        .cornerRadius(12)
    }
}

// MARK: - Sound Filter Sheet

struct SoundFilterSheet: View {
    @Binding var selectedElement: Element?
    @Binding var showingNewOnly: Bool
    @Binding var activeTagFilters: [String: Set<String>]
    @Environment(\.dismiss) private var dismiss
    
    let tagDimensions: [(key: String, label: String, values: [String])] = [
        ("domain", "Domain", ["water", "air", "fire", "earth", "mechanical", "organic", "electrical", "cosmic"]),
        ("rhythm", "Rhythm", ["steady", "pulse", "irregular", "chaotic", "rhythmic", "arrhythmic"]),
        ("register", "Register", ["sub", "deep", "mid", "bright", "full", "ultrasonic"]),
        ("context", "Context", ["nature", "domestic", "abstract", "urban", "industrial", "spiritual"]),
        ("weight", "Weight", ["ethereal", "light", "medium", "heavy", "massive"]),
        ("texture", "Texture", ["smooth", "rough", "crystalline", "diffuse", "granular", "glassy", "metallic"]),
        ("motion", "Motion", ["static", "flowing", "surging", "swirling", "oscillating", "drifting", "pulsing"]),
        ("density", "Density", ["vacuum", "sparse", "moderate", "dense", "saturated"]),
        ("temperature", "Temperature", ["cold", "cool", "neutral", "warm", "hot"]),
        ("polarity", "Polarity", ["active", "receptive", "balanced", "neutral"]),
        ("celestial", "Celestial", ["solar", "lunar", "stellar", "planetary", "void"]),
        ("archetype", "Archetype", ["maiden", "mother", "crone", "hero", "mentor", "shadow", "trickster"])
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Element") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedElement == nil,
                                color: .primary
                            ) {
                                selectedElement = nil
                            }
                            ForEach(Element.allCases) { element in
                                FilterChip(
                                    title: element.rawValue,
                                    isSelected: selectedElement == element,
                                    color: element.color
                                ) {
                                    selectedElement = element
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Toggle("Show New Only", isOn: $showingNewOnly)
                }
                
                ForEach(tagDimensions, id: \.key) { dimension in
                    Section(dimension.label) {
                        FlowLayout(spacing: 8) {
                            ForEach(dimension.values, id: \.self) { value in
                                let isSelected = activeTagFilters[dimension.key]?.contains(value) ?? false
                                FilterChip(
                                    title: value.capitalized,
                                    isSelected: isSelected,
                                    color: ThemeService.shared.accentColor
                                ) {
                                    if isSelected {
                                        activeTagFilters[dimension.key]?.remove(value)
                                        if activeTagFilters[dimension.key]?.isEmpty == true {
                                            activeTagFilters.removeValue(forKey: dimension.key)
                                        }
                                    } else {
                                        activeTagFilters[dimension.key, default: []].insert(value)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedElement = nil
                        showingNewOnly = false
                        activeTagFilters.removeAll()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
