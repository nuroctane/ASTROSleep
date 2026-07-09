package com.astrosleep.app.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface UserProfileDao {
    @Query("SELECT * FROM user_profile WHERE id = :id LIMIT 1")
    suspend fun get(id: String = "local"): UserProfileEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: UserProfileEntity)

    @Query("DELETE FROM user_profile")
    suspend fun clear()
}

@Dao
interface SavedComboDao {
    @Query("SELECT * FROM saved_combos ORDER BY updatedAtEpochMs DESC")
    suspend fun all(): List<SavedComboEntity>

    @Query("SELECT * FROM saved_combos WHERE id = :id LIMIT 1")
    suspend fun get(id: String): SavedComboEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: SavedComboEntity)

    @Query("DELETE FROM saved_combos WHERE id = :id")
    suspend fun delete(id: String)
}

@Dao
interface SessionLogDao {
    @Query("SELECT * FROM session_logs ORDER BY dateEpochMs DESC LIMIT :limit")
    suspend fun recent(limit: Int = 100): List<SessionLogEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: SessionLogEntity)
}

@Dao
interface AffirmationCacheDao {
    @Query("SELECT * FROM affirmation_cache WHERE id = :dateId LIMIT 1")
    suspend fun get(dateId: String): AffirmationCacheEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: AffirmationCacheEntity)
}
