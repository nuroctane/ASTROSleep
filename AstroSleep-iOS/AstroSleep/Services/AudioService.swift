import Foundation
import AVFoundation
import Combine

// MARK: - Audio Service
/// Multi-track audio engine with per-layer EQ, LFO oscillation, and background audio.
final class AudioService: ObservableObject {
    static let shared = AudioService()
    
    @Published var state: AudioState = .idle
    @Published var masterVolume: Double = 1.0
    @Published var isPlaying: Bool = false
    
    private var audioEngine: AVAudioEngine!
    private var mixer: AVAudioMixerNode!
    private var playerNodes: [UUID: AudioLayerNode] = [:]
    private var affirmationPlayer: AVAudioPlayerNode?
    private var displayLink: CADisplayLink?
    private var audioFiles: [String: AVAudioFile] = [:]
    
    private var sessionStartTime: Date?
    private var timer: Timer?
    private var sleepTimerMinutes: Int?
    
    private var lfoTimers: [UUID: Timer] = [:]
    private var fadeTimer: Timer?
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAudioSession()
        setupAudioEngine()
        setupNotifications()
    }
    
    deinit {
        stopAll()
        cleanup()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetoothA2DP, .allowBluetoothHFP])
            try session.setActive(true)
            
            // Handle interruptions
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
            
            // Handle route changes (headphones disconnect)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: nil
            )
        } catch {
            print("Audio session setup error: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        mixer = AVAudioMixerNode()
        
        audioEngine.attach(mixer)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) else {
            print("Failed to create audio format")
            return
        }
        audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: format)
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }
    
    private func setupNotifications() {
        // Setup any additional notification observers
    }
    
    // MARK: - Layer Management
    
    func loadCombo(_ combo: Combo) async throws {
        await MainActor.run { state = .loading }
        
        // Stop and cleanup existing layers
        stopAll()
        cleanupLayers()
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) else {
            await MainActor.run { state = .idle }
            throw AudioError.formatCreationFailed
        }
        
        // Build sound lookup for O(1) resolution
        let soundMap = Dictionary(
            uniqueKeysWithValues: SoundLibrary.shared.sounds.map { ($0.id, $0) }
        )
        
        // Build audio graph and load files in parallel
        await withTaskGroup(of: Void.self) { group in
            for layer in combo.layers {
                guard let sound = soundMap[layer.soundId] else { continue }
                group.addTask {
                    await self.loadAudioFile(for: sound)
                }
                
                // Build audio graph on main thread
                await MainActor.run {
                    self.attachLayer(layer: layer, sound: sound, format: format)
                }
            }
        }
        
        // Setup affirmation if available
        // (TTS handled separately via AVSpeechSynthesizer)
        
        await MainActor.run { state = .idle }
    }
    
    private func attachLayer(layer: AmbientLayer, sound: Sound, format: AVAudioFormat) {
        let playerNode = AVAudioPlayerNode()
        let eqNode = AVAudioUnitEQ(numberOfBands: 3)
        configureEQ(eqNode, with: layer.eq)
        
        let timePitch = AVAudioUnitTimePitch()
        timePitch.rate = Float(layer.playbackSpeed)
        timePitch.pitch = 0
        timePitch.overlap = 8.0
        
        audioEngine.attach(playerNode)
        audioEngine.attach(eqNode)
        audioEngine.attach(timePitch)
        
        audioEngine.connect(playerNode, to: timePitch, format: format)
        audioEngine.connect(timePitch, to: eqNode, format: format)
        audioEngine.connect(eqNode, to: mixer, format: format)
        
        let layerNode = AudioLayerNode(
            id: layer.id,
            playerNode: playerNode,
            eqNode: eqNode,
            timePitchNode: timePitch,
            sound: sound,
            volume: layer.volume,
            oscillation: layer.oscillation
        )
        
        playerNodes[layer.id] = layerNode
    }
    
    private func loadAudioFile(for sound: Sound) async {
        // Skip if already loaded
        if audioFiles[sound.id] != nil { return }
        
        // Try local file first (bundle or Documents cache)
        if let localPath = sound.localPath,
           FileManager.default.fileExists(atPath: localPath) {
            let fileURL = URL(fileURLWithPath: localPath)
            do {
                let audioFile = try AVAudioFile(forReading: fileURL)
                audioFiles[sound.id] = audioFile
            } catch {
                print("[AudioService] Error loading '\(sound.name)': \(error)")
            }
            return
        }
        
        // Download from CDN if not cached
        await downloadSound(sound)
    }
    
    private func downloadSound(_ sound: Sound) async {
        guard let url = URL(string: sound.cdnUrl) else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }
            
            // Save to local cache
            guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            let soundsDir = docs.appendingPathComponent("sounds", isDirectory: true)
            try? FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
            
            let fileURL = soundsDir.appendingPathComponent("\(sound.id).m4a")
            try data.write(to: fileURL)
            
            let audioFile = try AVAudioFile(forReading: fileURL)
            audioFiles[sound.id] = audioFile
        } catch {
            print("Download error for \(sound.name): \(error)")
        }
    }
    
    private func configureEQ(_ eqNode: AVAudioUnitEQ, with profile: EQProfile) {
        let bands = eqNode.bands
        
        // Bass band (low shelf, ~100Hz)
        if bands.count > 0 {
            bands[0].filterType = .lowShelf
            bands[0].frequency = 100
            bands[0].gain = Float((profile.bass - 0.5) * 24) // ±12dB
            bands[0].bypass = false
        }
        
        // Mid band (parametric, ~1000Hz)
        if bands.count > 1 {
            bands[1].filterType = .parametric
            bands[1].frequency = 1000
            bands[1].gain = Float((profile.mid - 0.5) * 24)
            bands[1].bandwidth = 1.0
            bands[1].bypass = false
        }
        
        // Treble band (high shelf, ~10000Hz)
        if bands.count > 2 {
            bands[2].filterType = .highShelf
            bands[2].frequency = 10000
            bands[2].gain = Float((profile.treble - 0.5) * 24)
            bands[2].bypass = false
        }
    }
    
    // MARK: - Playback Control
    
    func play() {
        guard !playerNodes.isEmpty else { return }
        
        if audioEngine.isRunning == false {
            do {
                try audioEngine.start()
            } catch {
                print("Engine start error: \(error)")
                return
            }
        }
        
        for (_, layerNode) in playerNodes {
            guard let audioFile = audioFiles[layerNode.sound.id] else { continue }
            
            layerNode.playerNode.stop()
            layerNode.playerNode.scheduleFile(audioFile, at: nil, completionHandler: nil)
            layerNode.playerNode.play()
            
            // Set initial volume
            layerNode.playerNode.volume = Float(layerNode.volume * masterVolume)
            
            // Start LFO if configured
            if let oscillation = layerNode.oscillation, oscillation.enabled {
                startLFO(for: layerNode.id, config: oscillation)
            }
        }
        
        sessionStartTime = Date()
        isPlaying = true
        state = .playing
        
        // Start sleep timer if set
        if let minutes = sleepTimerMinutes {
            startSleepTimer(minutes: minutes)
        }
    }
    
    func pause() {
        for (_, layerNode) in playerNodes {
            layerNode.playerNode.pause()
        }
        
        // Stop LFO timers
        for (_, timer) in lfoTimers {
            timer.invalidate()
        }
        lfoTimers.removeAll()
        
        isPlaying = false
        state = .paused
    }
    
    func resume() {
        if audioEngine.isRunning == false {
            try? audioEngine.start()
        }
        
        for (_, layerNode) in playerNodes {
            layerNode.playerNode.play()
            
            if let oscillation = layerNode.oscillation, oscillation.enabled {
                startLFO(for: layerNode.id, config: oscillation)
            }
        }
        
        isPlaying = true
        state = .playing
    }
    
    func stopAll() {
        for (_, layerNode) in playerNodes {
            layerNode.playerNode.stop()
        }
        
        // Stop all LFO timers
        for (_, timer) in lfoTimers {
            timer.invalidate()
        }
        lfoTimers.removeAll()
        
        // Stop sleep timer
        timer?.invalidate()
        timer = nil
        
        isPlaying = false
        state = .stopped
    }
    
    func fadeOut(duration: TimeInterval = 60.0, completion: (() -> Void)? = nil) {
        state = .fading
        fadeTimer?.invalidate()
        
        let startVolume = Float(masterVolume)
        let steps = 60
        let stepDuration = duration / Double(steps)
        let stepCounter = StepCounter()
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            stepCounter.value += 1
            let progress = Float(stepCounter.value) / Float(steps)
            let newVolume = startVolume * (1.0 - progress)
            
            self.masterVolume = Double(newVolume)
            self.updateVolumes()
            
            if stepCounter.value >= steps {
                timer.invalidate()
                self.fadeTimer = nil
                self.stopAll()
                completion?()
            }
        }
    }
    
    // MARK: - LFO Oscillation
    
    private func startLFO(for layerId: UUID, config: OscillationConfig) {
        let period = config.periodSeconds
        let minVol = Float(config.minVolume)
        let maxVol = Float(config.maxVolume)
        let phaseOffset = config.phaseOffset
        let startTime = CACurrentMediaTime()
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
            guard let self = self,
                  let layerNode = self.playerNodes[layerId] else { return }
            
            let elapsed = CACurrentMediaTime() - startTime
            let cyclePosition = fmod((elapsed / period) + phaseOffset, 1.0)
            
            let waveformValue: Float
            switch config.waveform {
            case .sine:
                waveformValue = sin(Float(cyclePosition) * 2.0 * .pi)
            case .triangle:
                let t = Float(cyclePosition)
                waveformValue = 4.0 * abs(t - 0.5) - 1.0
            case .step:
                waveformValue = cyclePosition < 0.5 ? -1.0 : 1.0
            case .perlin:
                // Simple noise approximation
                let t = Float(cyclePosition)
                waveformValue = sin(t * 6.28) * 0.5 + sin(t * 12.56) * 0.25 + sin(t * 25.12) * 0.125
            }
            
            let normalizedValue = (waveformValue + 1.0) / 2.0 // 0 to 1
            let volume = minVol + (maxVol - minVol) * normalizedValue
            layerNode.playerNode.volume = volume * Float(self.masterVolume)
        }
        
        lfoTimers[layerId] = timer
    }
    
    // MARK: - Volume Control
    
    func setMasterVolume(_ volume: Double) {
        masterVolume = max(0, min(1, volume))
        updateVolumes()
    }
    
    func setLayerVolume(layerId: UUID, volume: Double) {
        guard var layerNode = playerNodes[layerId] else { return }
        layerNode.volume = max(0, min(1, volume))
        playerNodes[layerId] = layerNode
        updateVolumes()
    }
    
    func setLayerSpeed(layerId: UUID, speed: Double) {
        guard let layerNode = playerNodes[layerId] else { return }
        layerNode.timePitchNode.rate = Float(max(0.5, min(2.0, speed)))
    }
    
    func updateEQ(layerId: UUID, profile: EQProfile) {
        guard let layerNode = playerNodes[layerId] else { return }
        configureEQ(layerNode.eqNode, with: profile)
    }
    
    private func updateVolumes() {
        for (_, layerNode) in playerNodes {
            let baseVolume = Float(layerNode.volume * masterVolume)
            // Don't override if LFO is active (LFO updates volume directly)
            if layerNode.oscillation?.enabled != true {
                layerNode.playerNode.volume = baseVolume
            }
        }
    }
    
    // MARK: - Sleep Timer
    
    func setSleepTimer(minutes: Int) {
        sleepTimerMinutes = minutes
        if isPlaying {
            startSleepTimer(minutes: minutes)
        }
    }
    
    private func startSleepTimer(minutes: Int) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            self?.fadeOut(duration: 60.0)
        }
    }
    
    // MARK: - Affirmation TTS
    
    func speakAffirmation(_ text: String, voiceId: String, volume: Double, rate: Double, pitchSemitones: Double = 0.0) {
        if speechSynthesizer == nil {
            speechSynthesizer = AVSpeechSynthesizer()
        }
        guard let synthesizer = speechSynthesizer else { return }
        
        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Use specific voice identifier if available (enables Siri voices and on-device voices)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let preferredVoice = voices.first { $0.identifier == voiceId }
            ?? voices.first { $0.name.contains(voiceId.lowercased().contains("male") ? "Male" : "Female") && $0.language.hasPrefix("en") }
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.voice = preferredVoice
        
        utterance.volume = Float(volume * masterVolume)
        utterance.rate = Float(rate * 0.4) // Subliminal speed
        // Convert semitones to pitch multiplier: 12 semitones = octave = 2x
        // pitchMultiplier 1.0 = no change. Each semitone = 2^(1/12) multiplier
        utterance.pitchMultiplier = Float(pow(2.0, pitchSemitones / 12.0))
        
        synthesizer.speak(utterance)
    }
    
    // MARK: - Interruption Handling
    
    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        switch type {
        case .began:
            if isPlaying {
                pause()
                state = .interrupted
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resume()
                }
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        
        if reason == .oldDeviceUnavailable {
            // Headphones disconnected - pause to prevent speaker bleed
            if isPlaying {
                pause()
            }
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanupLayers() {
        for (_, layerNode) in playerNodes {
            audioEngine.disconnectNodeOutput(layerNode.playerNode)
            audioEngine.detach(layerNode.playerNode)
            audioEngine.detach(layerNode.eqNode)
            audioEngine.detach(layerNode.timePitchNode)
        }
        playerNodes.removeAll()
    }
    
    func cleanup() {
        stopAll()
        fadeTimer?.invalidate()
        fadeTimer = nil
        speechSynthesizer?.stopSpeaking(at: .immediate)
        speechSynthesizer = nil
        cleanupLayers()
        audioEngine?.stop()
        audioEngine = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Session Info
    
    var currentSessionDuration: TimeInterval? {
        guard let startTime = sessionStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    func resetSession() {
        sessionStartTime = nil
    }
}

// MARK: - Audio Layer Node

private struct AudioLayerNode {
    let id: UUID
    let playerNode: AVAudioPlayerNode
    let eqNode: AVAudioUnitEQ
    let timePitchNode: AVAudioUnitTimePitch
    let sound: Sound
    var volume: Double
    var oscillation: OscillationConfig?
}

// MARK: - Step Counter
/// Reference-type counter for use in timer closures.
private final class StepCounter {
    var value: Int = 0
}

// MARK: - Audio Errors

enum AudioError: Error {
    case formatCreationFailed
    case engineStartFailed
    case fileLoadFailed
}
