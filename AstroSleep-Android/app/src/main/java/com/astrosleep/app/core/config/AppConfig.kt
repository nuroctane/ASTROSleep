package com.astrosleep.app.core.config

import com.astrosleep.app.BuildConfig

/**
 * Centralized configuration — mirrors iOS `AppConfig.swift`.
 * Values come from BuildConfig (local.properties / CI). Never hardcode secrets.
 */
object AppConfig {
    val supabaseUrl: String
        get() = BuildConfig.SUPABASE_URL.ifBlank { "https://localhost" }

    val supabaseAnonKey: String
        get() = BuildConfig.SUPABASE_ANON_KEY

    val revenueCatApiKey: String
        get() = BuildConfig.REVENUECAT_API_KEY

    val proxyBaseUrl: String
        get() = BuildConfig.PROXY_BASE_URL.ifBlank { "https://api.astrosleep.app/api" }

    val soundManifestUrl: String
        get() = BuildConfig.SOUND_MANIFEST_URL.ifBlank {
            "https://cdn.astrosleep.app/sounds_manifest.json"
        }
}
