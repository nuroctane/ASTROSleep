import Foundation
import CoreLocation

// MARK: - Geocoding Service
/// Wraps CLGeocoder for city-to-coordinate lookup. No location permissions required.
/// Uses the modern `geocodeAddressString(_:in:preferredLocale:)` API (iOS 15+)
/// for locale-aware results and better accuracy.
final class GeocodingService: @unchecked Sendable {
    static let shared = GeocodingService()
    private let geocoder = CLGeocoder()
    
    private init() {}
    
    /// Geocodes a human-readable city string to coordinates.
    /// - Parameter city: City name (e.g., "New York, NY")
    /// - Returns: A `GeocodingResult` with coordinates and formatted city name.
    func geocode(city: String) async throws -> GeocodingResult {
        // Use the newer overload with locale context for better region-aware matching.
        let placemarks = try await geocoder.geocodeAddressString(
            city,
            in: nil,
            preferredLocale: Locale.current
        )
        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw GeocodingError.noResults
        }
        
        let cityName = placemark.locality ?? placemark.name ?? city
        let timezone = placemark.timeZone?.identifier ?? TimeZone.current.identifier
        
        return GeocodingResult(
            city: cityName,
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            timezone: timezone
        )
    }
    
    func cancel() {
        geocoder.cancelGeocode()
    }
}

// MARK: - Geocoding Result

struct GeocodingResult: Sendable {
    let city: String
    let lat: Double
    let lng: Double
    let timezone: String
}

// MARK: - Geocoding Error

enum GeocodingError: Error, LocalizedError {
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .noResults:
            return "Could not find coordinates for that city. Please check the spelling and try again."
        }
    }
}
