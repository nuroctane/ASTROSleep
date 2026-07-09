package com.astrosleep.app.service

import com.astrosleep.app.core.config.AppConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import javax.inject.Inject
import javax.inject.Singleton

sealed class NetworkError : Exception() {
    data object RateLimited : NetworkError()
    data class Http(val code: Int, override val message: String) : NetworkError()
    data class Transport(override val cause: Throwable) : NetworkError()
}

@Singleton
class NetworkService @Inject constructor(
    private val client: OkHttpClient,
) {
    private val json = Json { ignoreUnknownKeys = true }
    private val mediaType = "application/json; charset=utf-8".toMediaType()

    @Serializable
    private data class AffirmationRequest(val intention: String, val userId: String)

    @Serializable
    private data class AffirmationResponse(val script: String? = null, val affirmation: String? = null)

    suspend fun generateAffirmation(intention: String, userId: String): String =
        withContext(Dispatchers.IO) {
            val body = json.encodeToString(
                AffirmationRequest.serializer(),
                AffirmationRequest(intention = intention, userId = userId),
            ).toRequestBody(mediaType)

            val request = Request.Builder()
                .url("${AppConfig.proxyBaseUrl.trimEnd('/')}/affirmation")
                .post(body)
                .header("Content-Type", "application/json")
                .build()

            try {
                client.newCall(request).execute().use { response ->
                    when (response.code) {
                        429 -> throw NetworkError.RateLimited
                        in 200..299 -> {
                            val text = response.body?.string().orEmpty()
                            val parsed = json.decodeFromString(AffirmationResponse.serializer(), text)
                            parsed.script ?: parsed.affirmation
                                ?: throw NetworkError.Http(response.code, "Empty affirmation")
                        }
                        else -> throw NetworkError.Http(
                            response.code,
                            response.body?.string() ?: "HTTP ${response.code}",
                        )
                    }
                }
            } catch (e: NetworkError) {
                throw e
            } catch (e: Exception) {
                throw NetworkError.Transport(e)
            }
        }
}
