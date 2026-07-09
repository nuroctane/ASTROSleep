import Foundation
import AVFoundation
import Combine

// MARK: - Audio Service
/// Multi-track audio engine with per-layer EQ, LFO oscillation, and background audio.
/// Critical fixes: ambient looping, main-thread graph access, timer-off, voice gender, volume after fade.
@MainActor
final class AudioService: ObservableObject {
    static let shared = AudioService()
    
    @Published var state: AudioState = .idle
    @Published var masterVolume: Double = 1.0
    @Published var isPlaying: Bool = false
    @Published var lastError: String?
    
    private var audioEngine: AVAudioEngine!
    private var mixer: AVAudioMixerNode!
    private var playerNodes: [UUID: AudioLayerNode] = [:]
    private var audioFiles: [String: AVAudioFile] = [:]
    
    private var sessionStartTime: Date?
    private var timer: Timer?
    private var sleepTimerMinutes: Int?
    
    private var lfoTimers: [UUID: Timer] = [:]
    private var fadeTimer: Timer?
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var volumeBeforeFade: Double = 1.0
    private var shouldLoopLayers: Bool = true
    
    private init() {
        setupAudioSession()
        setupAudioEngine()
        setupNotifications()
    }
    
    deinit {
        // Avoid calling MainActor-isolated methods from deinit; best-effort cleanup
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetoothA2DP, .allowBluetoothHFP])
            try session.setActive(true)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
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
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: format)
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }
    
    private func setupNotifications() {}
    
    // MARK: - Layer Management
    
    func loadCombo(_ combo: Combo) async throws {
        state = .loading
        lastError = nil
        stopAll(resetMasterVolume: false)
        cleanupLayers()
        if masterVolume < 0.05 {
            masterVolume = max(0.05, volumeBeforeFade)
        }
        
        // Serial file loads (thread-safe) then attach graph
        let soundMap = Dictionary(
            SoundLibrary.shared.sounds.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        
        for layer in combo.layers {
            guard let sound = soundMap[layer.soundId] else { continue }
            await loadAudioFile(for: sound)
            if let file = audioFiles[sound.id] {
                attachLayer(layer: layer, sound: sound, file: file)
            }
        }
        
        if playerNodes.isEmpty {
            state = .idle
            lastError = "No playable sounds loaded."
            throw AudioError.fileLoadFailed
        }
        state = .idle
    }
    
    private func attachLayer(layer: AmbientLayer, sound: Sound, file: AVAudioFile) {
        let format = file.processingFormat
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
        
        playerNodes[layer.id] = AudioLayerNode(
            id: layer.id,
            playerNode: playerNode,
            eqNode: eqNode,
            timePitchNode: timePitch,
            sound: sound,
            volume: layer.volume,
            oscillation: layer.oscillation,
            audioFile: file
        )
    }
    
    private func loadAudioFile(for sound: Sound) async {
        if audioFiles[sound.id] != nil { return }
        
        if let localPath = sound.localPath,
           FileManager.default.fileExists(atPath: localPath) {
            let fileURL = URL(fileURLWithPath: localPath)
            do {
                audioFiles[sound.id] = try AVAudioFile(forReading: fileURL)
            } catch {
                print("[AudioService] Error loading '\(sound.name)': \(error)")
            }
            return
        }
        
        await downloadSound(sound)
    }
    
    private func downloadSound(_ sound: Sound) async {
        guard let url = URL(string: sound.cdnUrl) else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }
            guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            let soundsDir = docs.appendingPathComponent("sounds", isDirectory: true)
            try? FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
            let fileURL = soundsDir.appendingPathComponent("\(sound.id).m4a")
            try data.write(to: fileURL)
            audioFiles[sound.id] = try AVAudioFile(forReading: fileURL)
        } catch {
            print("Download error for \(sound.name): \(error)")
        }
    }
    
    private func configureEQ(_ eqNode: AVAudioUnitEQ, with profile: EQProfile) {
        let bands = eqNode.bands
        if bands.count > 0 {
            bands[0].filterType = .lowShelf
            bands[0].frequency = 100
            bands[0].gain = Float((profile.bass - 0.5) * 24)
            bands[0].bypass = false
        }
        if bands.count > 1 {
            bands[1].filterType = .parametric
            bands[1].frequency = 1000
            bands[1].gain = Float((profile.mid - 0.5) * 24)
            bands[1].bandwidth = 1.0
            bands[1].bypass = false
        }
        if bands.count > 2 {
            bands[2].filterType = .highShelf
            bands[2].frequency = 10000
            bands[2].gain = Float((profile.treble - 0.5) * 24)
            bands[2].bypass = false
        }
    }
    
    // MARK: - Playback Control
    
    func play() {
        guard !playerNodes.isEmpty else {
            lastError = "Nothing to play."
            return
        }
        
        if audioEngine.isRunning == false {
            do {
                try audioEngine.start()
            } catch {
                print("Engine start error: \(error)")
                lastError = error.localizedDescription
                return
            }
        }
        
        shouldLoopLayers = true
        for (id, layerNode) in playerNodes {
            scheduleLooping(layerId: id, layerNode: layerNode)
            layerNode.playerNode.volume = Float(layerNode.volume * masterVolume)
            layerNode.playerNode.play()
            
            if let oscillation = layerNode.oscillation, oscillation.enabled {
                startLFO(for: id, config: oscillation, baseVolume: layerNode.volume)
            }
        }
        
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        isPlaying = true
        state = .playing
        
        if let minutes = sleepTimerMinutes, minutes > 0 {
            startSleepTimer(minutes: minutes)
        }
    }
    
    /// Schedule file and re-schedule on completion while looping is enabled.
    private func scheduleLooping(layerId: UUID, layerNode: AudioLayerNode) {
        guard let file = layerNode.audioFile else { return }
        layerNode.playerNode.stop()
        // Seek file to start for each schedule
        file.framePosition = 0
        layerNode.playerNode.scheduleFile(file, at: nil, completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                guard self.shouldLoopLayers, self.isPlaying,
                      let node = self.playerNodes[layerId] else { return }
                self.scheduleLooping(layerId: layerId, layerNode: node)
                if !node.playerNode.isPlaying {
                    node.playerNode.play()
                }
            }
        })
    }
    
    func pause() {
        shouldLoopLayers = false
        for (_, layerNode) in playerNodes {
            layerNode.playerNode.pause()
        }
        for (_, timer) in lfoTimers {
            timer.invalidate()
        }
        lfoTimers.removeAll()
        isPlaying = false
        state = .paused
    }
    
    func resume() {
        if state == .stopped || playerNodes.isEmpty {
            // Need full re-schedule after stop
            play()
            return
        }
        shouldLoopLayers = true
        if audioEngine.isRunning == false {
            try? audioEngine.start()
        }
        for (id, layerNode) in playerNodes {
            // If nothing is scheduled, re-schedule
            if !layerNode.playerNode.isPlaying {
                scheduleLooping(layerId: id, layerNode: layerNode)
            }
            layerNode.playerNode.play()
            if let oscillation = layerNode.oscillation, oscillation.enabled {
                startLFO(for: id, config: oscillation, baseVolume: layerNode.volume)
            }
        }
        isPlaying = true
        state = .playing
    }
    
    func stopAll(resetMasterVolume: Bool = true) {
        shouldLoopLayers = false
        for (_, layerNode) in playerNodes {
            layerNode.playerNode.stop()
        }
        for (_, timer) in lfoTimers {
            timer.invalidate()
        }
        lfoTimers.removeAll()
        timer?.invalidate()
        timer = nil
        fadeTimer?.invalidate()
        fadeTimer = nil
        isPlaying = false
        state = .stopped
        if resetMasterVolume {
            masterVolume = max(0.05, volumeBeforeFade)
            updateVolumes()
        }
    }
    
    func fadeOut(duration: TimeInterval = 60.0, completion: (() -> Void)? = nil) {
        state = .fading
        fadeTimer?.invalidate()
        volumeBeforeFade = max(0.05, masterVolume)
        
        let startVolume = Float(masterVolume)
        let steps = 60
        let stepDuration = duration / Double(steps)
        let stepCounter = StepCounter()
        
        let t = Timer(timeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                stepCounter.value += 1
                let progress = Float(stepCounter.value) / Float(steps)
                let newVolume = startVolume * (1.0 - progress)
                self.masterVolume = Double(newVolume)
                self.updateVolumes()
                if stepCounter.value >= steps {
                    timer.invalidate()
                    self.fadeTimer = nil
                    self.stopAll(resetMasterVolume: true)
                    completion?()
                }
            }
        }
        RunLoop.main.add(t, forMode: .common)
        fadeTimer = t
    }
    
    // MARK: - LFO Oscillation
    
    private func startLFO(for layerId: UUID, config: OscillationConfig, baseVolume: Double) {
        lfoTimers[layerId]?.invalidate()
        let period = config.periodSeconds
        let minVol = Float(config.minVolume)
        let maxVol = Float(config.maxVolume)
        let phaseOffset = config.phaseOffset
        let startTime = CACurrentMediaTime()
        let base = Float(baseVolume)
        
        let t = Timer(timeInterval: 0.06, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard let layerNode = self.playerNodes[layerId] else { return }
                let elapsed = CACurrentMediaTime() - startTime
                let cyclePosition = fmod((elapsed / period) + phaseOffset, 1.0)
                
                let waveformValue: Float
                switch config.waveform {
                case .sine:
                    waveformValue = sin(Float(cyclePosition) * 2.0 * .pi)
                case .triangle:
                    let tt = Float(cyclePosition)
                    waveformValue = 4.0 * abs(tt - 0.5) - 1.0
                case .step:
                    waveformValue = cyclePosition < 0.5 ? -1.0 : 1.0
                case .perlin:
                    let tt = Float(cyclePosition)
                    waveformValue = sin(tt * 6.28) * 0.5 + sin(tt * 12.56) * 0.25 + sin(tt * 25.12) * 0.125
                }
                
                let normalizedValue = (waveformValue + 1.0) / 2.0
                let lfo = minVol + (maxVol - minVol) * normalizedValue
                layerNode.playerNode.volume = base * lfo * Float(self.masterVolume)
            }
        }
        RunLoop.main.add(t, forMode: .common)
        lfoTimers[layerId] = t
    }
    
    // MARK: - Volume Control
    
    func setMasterVolume(_ volume: Double) {
        masterVolume = max(0, min(1, volume))
        if state != .fading {
            volumeBeforeFade = masterVolume
        }
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
            if layerNode.oscillation?.enabled != true {
                layerNode.playerNode.volume = baseVolume
            }
        }
    }
    
    // MARK: - Sleep Timer
    
    func setSleepTimer(minutes: Int) {
        if minutes <= 0 {
            sleepTimerMinutes = nil
            timer?.invalidate()
            timer = nil
            return
        }
        sleepTimerMinutes = minutes
        if isPlaying {
            startSleepTimer(minutes: minutes)
        }
    }
    
    private func startSleepTimer(minutes: Int) {
        guard minutes > 0 else {
            timer?.invalidate()
            timer = nil
            return
        }
        timer?.invalidate()
        let t = Timer(timeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.fadeOut(duration: 60.0)
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
    
    // MARK: - Affirmation TTS
    
    func speakAffirmation(_ text: String, voiceId: String, volume: Double, rate: Double, pitchSemitones: Double = 0.0) {
        if speechSynthesizer == nil {
            speechSynthesizer = AVSpeechSynthesizer()
        }
        guard let synthesizer = speechSynthesizer else { return }
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let lower = voiceId.lowercased()
        let preferredVoice: AVSpeechSynthesisVoice?
        if let exact = voices.first(where: { $0.identifier == voiceId }) {
            preferredVoice = exact
        } else if lower.contains("female") || lower == "female" {
            preferredVoice = voices.first {
                $0.language.hasPrefix("en") &&
                ($0.name.localizedCaseInsensitiveContains("female") ||
                 $0.identifier.localizedCaseInsensitiveContains("female") ||
                 $0.identifier.localizedCaseInsensitiveContains("samantha") ||
                 $0.identifier.localizedCaseInsensitiveContains("siri"))
            }
        } else if lower.contains("male") {
            preferredVoice = voices.first {
                $0.language.hasPrefix("en") &&
                ($0.name.localizedCaseInsensitiveContains("male") ||
                 $0.identifier.localizedCaseInsensitiveContains("male"))
            }
        } else {
            preferredVoice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.voice = preferredVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = Float(volume * masterVolume)
        utterance.rate = Float(rate * 0.4)
        utterance.pitchMultiplier = Float(pow(2.0, pitchSemitones / 12.0))
        synthesizer.speak(utterance)
    }
    
    // MARK: - Interruption Handling
    
    @objc private func handleAudioInterruption(_ notification: Notification) {
        Task { @MainActor in
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
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        Task { @MainActor in
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
            if reason == .oldDeviceUnavailable, isPlaying {
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
    var audioFile: AVAudioFile?
}

private final class StepCounter {
    var value: Int = 0
}

enum AudioError: Error {
    case formatCreationFailed
    case engineStartFailed
    case fileLoadFailed
}
