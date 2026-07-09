package com.astrosleep.app.data.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "user_profile")
data class UserProfileEntity(
    @PrimaryKey val id: String = "local",
    val json: String,
)

@Entity(tableName = "saved_combos")
data class SavedComboEntity(
    @PrimaryKey val id: String,
    val json: String,
    val updatedAtEpochMs: Long = System.currentTimeMillis(),
)

@Entity(tableName = "session_logs")
data class SessionLogEntity(
    @PrimaryKey val id: String,
    val json: String,
    val dateEpochMs: Long,
)

@Entity(tableName = "affirmation_cache")
data class AffirmationCacheEntity(
    @PrimaryKey val id: String, // YYYY-MM-DD
    val json: String,
)
