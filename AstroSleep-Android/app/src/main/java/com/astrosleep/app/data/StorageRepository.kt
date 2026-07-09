package com.astrosleep.app.data

import com.astrosleep.app.core.model.AffirmationCache
import com.astrosleep.app.core.model.Combo
import com.astrosleep.app.core.model.SessionLog
import com.astrosleep.app.core.model.UserProfile
import com.astrosleep.app.data.db.AffirmationCacheEntity
import com.astrosleep.app.data.db.AstroSleepDatabase
import com.astrosleep.app.data.db.SavedComboEntity
import com.astrosleep.app.data.db.SessionLogEntity
import com.astrosleep.app.data.db.UserProfileEntity
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Local persistence — birth data never leaves the device.
 * Port of iOS StorageService (Core Data → Room).
 */
@Singleton
class StorageRepository @Inject constructor(
    private val db: AstroSleepDatabase,
) {
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    suspend fun loadProfile(): UserProfile? {
        val entity = db.userProfileDao().get() ?: return null
        return runCatching { json.decodeFromString<UserProfile>(entity.json) }.getOrNull()
    }

    suspend fun saveProfile(profile: UserProfile) {
        db.userProfileDao().upsert(
            UserProfileEntity(id = "local", json = json.encodeToString(profile)),
        )
    }

    suspend fun updateProfile(transform: (UserProfile) -> UserProfile): UserProfile? {
        val current = loadProfile() ?: return null
        val updated = transform(current)
        saveProfile(updated)
        return updated
    }

    suspend fun loadCombos(): List<Combo> =
        db.savedComboDao().all().mapNotNull {
            runCatching { json.decodeFromString<Combo>(it.json) }.getOrNull()
        }

    suspend fun saveCombo(combo: Combo) {
        db.savedComboDao().upsert(
            SavedComboEntity(id = combo.id, json = json.encodeToString(combo)),
        )
    }

    suspend fun deleteCombo(id: String) {
        db.savedComboDao().delete(id)
    }

    suspend fun logSession(log: SessionLog) {
        db.sessionLogDao().insert(
            SessionLogEntity(
                id = log.id,
                json = json.encodeToString(log),
                dateEpochMs = log.dateEpochMs,
            ),
        )
    }

    suspend fun loadAffirmationCache(dateId: String): AffirmationCache? {
        val entity = db.affirmationCacheDao().get(dateId) ?: return null
        return runCatching { json.decodeFromString<AffirmationCache>(entity.json) }.getOrNull()
    }

    suspend fun cacheAffirmation(cache: AffirmationCache) {
        db.affirmationCacheDao().upsert(
            AffirmationCacheEntity(id = cache.id, json = json.encodeToString(cache)),
        )
    }
}
