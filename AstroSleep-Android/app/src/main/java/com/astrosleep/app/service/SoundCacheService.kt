package com.astrosleep.app.service

import android.content.Context
import com.astrosleep.app.core.model.SoundLibrary
import dagger.hilt.android.qualifiers.ApplicationContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Bundle → filesDir cache → CDN download for ambient assets.
 * Keeps birth data offline; only public sound files leave the network path.
 */
@Singleton
class SoundCacheService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val soundLibrary: SoundLibrary,
    private val client: OkHttpClient,
) {
    private val soundsDir: File
        get() = File(context.filesDir, "sounds").also { if (!it.exists()) it.mkdirs() }

    fun cachedFile(soundId: String): File = File(soundsDir, "$soundId.m4a")

    fun isCached(soundId: String): Boolean = cachedFile(soundId).exists()

    /**
     * Ensure a playable URI for [soundId].
     * Order: app assets → local cache → download CDN into cache.
     * @return file:// or asset:// URI, or null if unavailable
     */
    fun ensureCached(soundId: String): String? {
        val sound = soundLibrary.sound(soundId) ?: return null
        sound.bundleFilename?.let { name ->
            try {
                context.assets.openFd("sounds/$name").close()
                return "asset:///sounds/$name"
            } catch (_: Exception) {
                // not bundled
            }
        }
        val cache = cachedFile(soundId)
        if (cache.exists() && cache.length() > 0) {
            return cache.toURI().toString()
        }
        val url = sound.cdnUrl.trim()
        if (url.isBlank()) return null
        return try {
            downloadTo(cache, url)
            if (cache.exists() && cache.length() > 0) cache.toURI().toString() else null
        } catch (_: Exception) {
            cache.delete()
            null
        }
    }

    @Throws(IOException::class)
    private fun downloadTo(dest: File, url: String) {
        val request = Request.Builder().url(url).get().build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw IOException("HTTP ${response.code} for $url")
            }
            val body = response.body ?: throw IOException("Empty body")
            val tmp = File(dest.parentFile, dest.name + ".part")
            tmp.outputStream().use { out ->
                body.byteStream().use { input -> input.copyTo(out) }
            }
            if (!tmp.renameTo(dest)) {
                tmp.copyTo(dest, overwrite = true)
                tmp.delete()
            }
        }
    }

    /** Prefetch top-N sound ids in the background (best-effort). */
    fun prefetch(soundIds: List<String>) {
        for (id in soundIds) {
            try {
                ensureCached(id)
            } catch (_: Exception) {
            }
        }
    }
}
