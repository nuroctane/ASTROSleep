import Foundation
import CoreLocation
import Combine

// MARK: - Location Permission Service
/// Manages location permission requests and current location fetching for transit scoring.
final class LocationPermissionService: NSObject, ObservableObject {
    static let shared = LocationPermissionService()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        authorizationStatus = locationManager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                Task { @MainActor in
                    self.continuation = nil
                    locationManager.requestWhenInUseAuthorization()
                }
                // Poll until status changes
                Task {
                    var attempts = 0
                    while attempts < 50 {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        let status = self.locationManager.authorizationStatus
                        if status != .notDetermined {
                            await MainActor.run {
                                self.authorizationStatus = status
                                continuation.resume(returning: status == .authorizedWhenInUse || status == .authorizedAlways)
                            }
                            return
                        }
                        attempts += 1
                    }
                    continuation.resume(returning: false)
                }
            }
        @unknown default:
            return false
        }
    }
    
    // MARK: - Current Location
    
    func fetchCurrentLocation() async throws -> CLLocation {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.notAuthorized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                self.continuation = continuation
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    func reverseGeocode(_ location: CLLocation) async throws -> String {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else {
            throw LocationError.geocodingFailed
        }
        let city = placemark.locality ?? placemark.subAdministrativeArea ?? "Unknown"
        let state = placemark.administrativeArea ?? ""
        return state.isEmpty ? city : "\(city), \(state)"
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationPermissionService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationManager.stopUpdatingLocation()
        
        if let continuation = continuation {
            continuation.resume(returning: location)
            self.continuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        
        if let continuation = continuation {
            continuation.resume(throwing: error)
            self.continuation = nil
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

// MARK: - Errors

enum LocationError: LocalizedError {
    case notAuthorized
    case geocodingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Location access is required for transit scoring. Please enable it in Settings."
        case .geocodingFailed: return "Could not determine your city from location coordinates."
        }
    }
}
