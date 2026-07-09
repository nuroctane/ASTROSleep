import Foundation
import UIKit
import AuthenticationServices
import CryptoKit

// MARK: - Auth Service
/// Manages user authentication using Supabase Auth + Apple Sign-In.
/// Auth tokens stored securely in Keychain. Birth data NEVER sent to server.
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUserId: String?
    @Published var authError: String?
    
    private let supabaseURL = AppConfig.supabaseURL
    private let supabaseAnonKey = AppConfig.supabaseAnonKey
    private var currentNonce: String?
    
    private init() {
        // Check for existing session on launch
        checkExistingSession()
    }
    
    // MARK: - Email/Password Auth
    
    func signUp(email: String, password: String, name: String) async throws -> String {
        let url = supabaseURL.appendingPathComponent("/auth/v1/signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = [
            "email": email,
            "password": password,
            "data": ["name": name]
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.signUpFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let userId = json?["user"] as? [String: Any],
              let id = userId["id"] as? String else {
            throw AuthError.invalidResponse
        }
        
        // Store tokens securely
        if let accessToken = json?["access_token"] as? String,
           let refreshToken = json?["refresh_token"] as? String {
            try await SecureStorage.saveToken(accessToken, key: "access_token")
            try await SecureStorage.saveToken(refreshToken, key: "refresh_token")
        }
        
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUserId = id
        }
        
        return id
    }
    
    func signIn(email: String, password: String) async throws -> String {
        let url = supabaseURL.appendingPathComponent("/auth/v1/token?grant_type=password")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.invalidCredentials
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let user = json?["user"] as? [String: Any],
              let id = user["id"] as? String else {
            throw AuthError.invalidResponse
        }
        
        // Store tokens securely
        if let accessToken = json?["access_token"] as? String,
           let refreshToken = json?["refresh_token"] as? String {
            try await SecureStorage.saveToken(accessToken, key: "access_token")
            try await SecureStorage.saveToken(refreshToken, key: "refresh_token")
        }
        
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUserId = id
        }
        
        return id
    }
    
    func signOut() async throws {
        try await SecureStorage.deleteToken(key: "access_token")
        try await SecureStorage.deleteToken(key: "refresh_token")
        
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUserId = nil
        }
    }
    
    func resetPassword(email: String) async throws {
        let url = supabaseURL.appendingPathComponent("/auth/v1/recover")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.resetFailed
        }
    }
    
    // MARK: - Apple Sign-In
    
    func signInWithApple() async throws -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            let delegate = SignInWithAppleDelegate(continuation: continuation)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
            
            // Keep delegate alive
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
        
        guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.appleSignInFailed
        }
        
        // Exchange Apple ID token with Supabase
        let url = supabaseURL.appendingPathComponent("/auth/v1/token?grant_type=id_token")
        var tokenRequest = URLRequest(url: url)
        tokenRequest.httpMethod = "POST"
        tokenRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        tokenRequest.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "provider": "apple",
            "id_token": idTokenString,
            "nonce": nonce
        ]
        tokenRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: tokenRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.appleSignInFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let user = json?["user"] as? [String: Any],
              let id = user["id"] as? String else {
            throw AuthError.invalidResponse
        }
        
        if let accessToken = json?["access_token"] as? String,
           let refreshToken = json?["refresh_token"] as? String {
            try await SecureStorage.saveToken(accessToken, key: "access_token")
            try await SecureStorage.saveToken(refreshToken, key: "refresh_token")
        }
        
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUserId = id
        }
        
        return id
    }
    
    // MARK: - Session Management
    
    func checkExistingSession() {
        Task {
            do {
                if let accessToken = try await SecureStorage.getToken(key: "access_token"),
                   !accessToken.isEmpty {
                    // Validate token with Supabase
                    let url = supabaseURL.appendingPathComponent("/auth/v1/user")
                    var request = URLRequest(url: url)
                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse,
                       httpResponse.statusCode == 200 {
                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        let uid = json?["id"] as? String
                        await MainActor.run {
                            self.isAuthenticated = true
                            self.currentUserId = uid
                        }
                    } else {
                        try await refreshSession()
                        // Re-validate identity after token refresh
                        await fetchAndApplyUser()
                    }
                }
            } catch {
                print("Session check error: \(error)")
            }
        }
    }
    
    func refreshSession() async throws {
        guard let refreshToken = try await SecureStorage.getToken(key: "refresh_token") else {
            throw AuthError.noRefreshToken
        }
        
        let url = supabaseURL.appendingPathComponent("/auth/v1/token?grant_type=refresh_token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.sessionExpired
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let newAccessToken = json?["access_token"] as? String,
           let newRefreshToken = json?["refresh_token"] as? String {
            try await SecureStorage.saveToken(newAccessToken, key: "access_token")
            try await SecureStorage.saveToken(newRefreshToken, key: "refresh_token")
        }
        // Prefer user object nested in refresh response when present
        if let user = json?["user"] as? [String: Any], let id = user["id"] as? String {
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUserId = id
            }
        }
    }

    /// GET /auth/v1/user and set currentUserId + isAuthenticated.
    private func fetchAndApplyUser() async {
        do {
            guard let accessToken = try await SecureStorage.getToken(key: "access_token"),
                  !accessToken.isEmpty else { return }
            let url = supabaseURL.appendingPathComponent("/auth/v1/user")
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let uid = json?["id"] as? String
            await MainActor.run {
                self.isAuthenticated = uid != nil
                self.currentUserId = uid
            }
        } catch {
            print("fetchAndApplyUser error: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Auth Errors

enum AuthError: Error {
    case signUpFailed
    case invalidCredentials
    case invalidResponse
    case resetFailed
    case appleSignInFailed
    case noRefreshToken
    case sessionExpired
}

// MARK: - Sign In With Apple Delegate

private class SignInWithAppleDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let continuation: CheckedContinuation<ASAuthorization, Error>
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            return window
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return UIWindow(windowScene: scene)
        }
        return UIWindow(frame: UIScreen.main.bounds)
    }
}

// MARK: - Secure Storage

enum SecureStorage {
    static func saveToken(_ token: String, key: String) async throws {
        guard let data = token.data(using: .utf8) else {
            throw SecureStorageError.saveFailed
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.astrosleep.\(key)",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete existing by class+account only (including kSecValueData prevents match).
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.astrosleep.\(key)"
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureStorageError.saveFailed
        }
    }
    
    static func getToken(key: String) async throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.astrosleep.\(key)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    static func deleteToken(key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.astrosleep.\(key)"
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum SecureStorageError: Error {
    case saveFailed
}
