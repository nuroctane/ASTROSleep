package com.astrosleep.app.di

import android.content.Context
import androidx.room.Room
import com.astrosleep.app.data.db.AstroSleepDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AstroSleepDatabase =
        Room.databaseBuilder(context, AstroSleepDatabase::class.java, "astrosleep.db")
            // Prefer explicit migrations in production. Destructive wipe only as last resort
            // and logs loss of local birth data — never ship silent data loss without notice.
            .fallbackToDestructiveMigrationOnDowngrade()
            .build()

    @Provides
    @Singleton
    fun provideOkHttp(): OkHttpClient =
        OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .build()
}
