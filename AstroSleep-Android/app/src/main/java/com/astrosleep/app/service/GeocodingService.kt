package com.astrosleep.app.service

import android.content.Context
import android.location.Geocoder
import com.astrosleep.app.core.model.GeocodingResult
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Locale
import java.util.TimeZone
import javax.inject.Inject
import javax.inject.Singleton

class GeocodingException(message: String) : Exception(message)

/**
 * City → lat/lng via Android [Geocoder]. No special permission required for forward geocode.
 * Birth coordinates stay on-device after resolution.
 */
@Singleton
class GeocodingService @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    suspend fun geocode(city: String): GeocodingResult = withContext(Dispatchers.IO) {
        val query = city.trim()
        if (query.isEmpty()) {
            throw GeocodingException("Enter a city name.")
        }
        if (!Geocoder.isPresent()) {
            throw GeocodingException("Geocoder unavailable on this device. Enter coordinates manually.")
        }
        @Suppress("DEPRECATION")
        val results = try {
            Geocoder(context, Locale.getDefault()).getFromLocationName(query, 5)
        } catch (e: Exception) {
            throw GeocodingException(e.message ?: "Geocoding failed. Check network and spelling.")
        }
        val match = results?.firstOrNull { it.hasLatitude() && it.hasLongitude() }
            ?: throw GeocodingException("Could not find coordinates for that city. Check spelling and try again.")
        val cityName = match.locality
            ?: match.subAdminArea
            ?: match.adminArea
            ?: match.featureName
            ?: query
        GeocodingResult(
            city = cityName,
            lat = match.latitude,
            lng = match.longitude,
            timezone = TimeZone.getDefault().id,
        )
    }
}
