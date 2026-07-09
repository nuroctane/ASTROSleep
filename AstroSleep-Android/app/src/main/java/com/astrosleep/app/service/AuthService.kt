package com.astrosleep.app.service

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Auth shell — local anonymous user id in encrypted prefs.
 * Supabase email / Google Sign-In wire-up is Phase C.
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

    val currentUserId: String?
        get() = _userId.value

    private fun ensureLocalUserId(): String {
        val existing = prefs.getString(KEY_USER_ID, null)
        if (existing != null) return existing
        val id = UUID.randomUUID().toString()
        prefs.edit().putString(KEY_USER_ID, id).apply()
        return id
    }

    fun signOutLocal() {
        prefs.edit().clear().apply()
        _userId.value = ensureLocalUserId()
    }

    companion object {
        private const val KEY_USER_ID = "user_id"
    }
}
