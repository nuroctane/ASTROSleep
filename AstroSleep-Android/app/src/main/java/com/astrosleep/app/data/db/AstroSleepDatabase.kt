package com.astrosleep.app.data.db

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        UserProfileEntity::class,
        SavedComboEntity::class,
        SessionLogEntity::class,
        AffirmationCacheEntity::class,
    ],
    version = 1,
    exportSchema = false,
)
abstract class AstroSleepDatabase : RoomDatabase() {
    abstract fun userProfileDao(): UserProfileDao
    abstract fun savedComboDao(): SavedComboDao
    abstract fun sessionLogDao(): SessionLogDao
    abstract fun affirmationCacheDao(): AffirmationCacheDao
}
