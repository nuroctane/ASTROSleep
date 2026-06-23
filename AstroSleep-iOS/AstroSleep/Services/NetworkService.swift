import Foundation

// MARK: - Network Service
/// Handles all network communication. API keys NEVER stored in app binary.
final class NetworkService {
    static let shared = NetworkService()
    
    private let proxyURL = AppConfig.proxyBaseURL
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - AI Affirmation Generation
    
    /// Generates a subliminal affirmation script via the Cloudflare proxy.
    /// Rate limited to 1 per calendar day per user.
    func generateAffirmation(intention: String, userId: String) async throws -> String {
        guard intention.count <= 280 else {
            throw NetworkError.invalidInput
        }
        
        let accessToken = try await SecureStorage.getToken(key: "access_token")
        
        let url = proxyURL.appendingPathComponent("/affirmation")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "intention": intention,
            "user_id": userId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknownError
        }
        
        switch httpResponse.statusCode {
        case 200:
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let script = json?["script"] as? String else {
                throw NetworkError.invalidResponse
            }
            return script
            
        case 429:
            // Rate limited
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let error = json?["error"] as? String, error == "limit_reached" {
                throw NetworkError.rateLimited
            }
            throw NetworkError.rateLimited
            
        case 503:
            throw NetworkError.upstreamError
            
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Transit Narrative (Pro)
    
    func generateTransitNarrative(transits: [Transit], userId: String) async throws -> String {
        let accessToken = try await SecureStorage.getToken(key: "access_token")
        
        let url = proxyURL.appendingPathComponent("/transit-narrative")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let transitData = transits.map { [
            "planet": $0.planet.rawValue,
            "aspect": $0.aspectType.rawValue,
            "strength": $0.strength
        ] }
        
        let body: [String: Any] = [
            "user_id": userId,
            "transits": transitData
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["narrative"] as? String ?? ""
    }
    
    // MARK: - Sound Manifest Fetch
    
    func fetchSoundManifest() async throws -> SoundManifest {
        let url = AppConfig.soundManifestURL
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.manifestFetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SoundManifest.self, from: data)
    }
    
    // MARK: - Sound Download
    
    func downloadSound(_ sound: Sound) async throws -> Data {
        guard let url = URL(string: sound.cdnUrl) else {
            throw NetworkError.downloadFailed
        }
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.downloadFailed
        }
        
        return data
    }
}

// MARK: - Network Errors

enum NetworkError: Error {
    case invalidInput
    case invalidResponse
    case rateLimited
    case upstreamError
    case serverError(Int)
    case manifestFetchFailed
    case downloadFailed
    case unknownError
    
    var userFacingMessage: String {
        switch self {
        case .rateLimited:
            return "Daily affirmation limit reached. Try again tomorrow."
        case .upstreamError:
            return "AI service temporarily unavailable. Starting without affirmation."
        case .serverError:
            return "Server error. Starting without affirmation."
        case .manifestFetchFailed:
            return "Could not update sound library. Using cached version."
        case .downloadFailed:
            return "Could not download sound. Please check your connection."
        default:
            return "Network error. Please try again."
        }
    }
}
