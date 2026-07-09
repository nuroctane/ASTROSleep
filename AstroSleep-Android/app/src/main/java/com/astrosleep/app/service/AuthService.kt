package com.astrosleep.app.service

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.astrosleep.app.core.config.AppConfig
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Auth shell — local anonymous user id + optional email identity in encrypted prefs.
 * When Supabase URL/anon key are configured, [linkEmail] will be the hook for magic-link / OAuth.
 * Birth chart data is never stored here (Room only).
 */
@Singleton
class AuthService @Inject constructor(
    @ApplicationContext context: Context,
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs = EncryptedSharedPreferences.create(
        context,
        "astrosleep_auth",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )

    private val _userId = MutableStateFlow(ensureLocalUserId())
    val userId: StateFlow<String?> = _userId.asStateFlow()

    private val _email = MutableStateFlow(prefs.getString(KEY_EMAIL, null))
    val email: StateFlow<String?> = _email.asStateFlow()

    private val _statusMessage = MutableStateFlow<String?>(null)
    val statusMessage: StateFlow<String?> = _statusMessage.asStateFlow()

    val currentUserId: String?
        get() = _userId.value

    val supabaseReady: Boolean
        get() {
            val url = AppConfig.supabaseUrl
            return url.isNotBlank() &&
                !url.contains("localhost", ignoreCase = true) &&
                AppConfig.supabaseAnonKey.isNotBlank()
        }

    private fun ensureLocalUserId(): String {
        val existing = prefs.getString(KEY_USER_ID, null)
        if (existing != null) return existing
        val id = UUID.randomUUID().toString()
        prefs.edit().putString(KEY_USER_ID, id).apply()
        return id
    }

    /**
     * Persist email for restore identity. When Supabase is configured, this is the
     * attachment point for OTP / magic link (network call left to NetworkService).
     */
    fun linkEmail(email: String) {
        val normalized = email.trim().lowercase()
        if (normalized.isEmpty() || !normalized.contains("@")) {
            _statusMessage.value = "Enter a valid email."
            return
        }
        prefs.edit().putString(KEY_EMAIL, normalized).apply()
        _email.value = normalized
        _statusMessage.value = if (supabaseReady) {
            "Email saved. Supabase keys present — wire magic-link send next."
        } else {
            "Email saved locally for identity. Add Supabase keys for cloud auth."
        }
    }

    fun signOutLocal() {
        prefs.edit().clear().apply()
        _email.value = null
        _userId.value = ensureLocalUserId()
        _statusMessage.value = "Local session rotated. New anonymous id issued."
    }

    fun clearStatus() {
        _statusMessage.value = null
    }

    companion object {
        private const val KEY_USER_ID = "user_id"
        private const val KEY_EMAIL = "email"
    }
}
