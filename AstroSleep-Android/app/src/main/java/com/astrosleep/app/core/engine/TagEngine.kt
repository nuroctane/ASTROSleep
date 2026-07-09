package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.ElementVector
import com.astrosleep.app.core.model.RankedSound
import com.astrosleep.app.core.model.Sound
import com.astrosleep.app.core.model.SoundTags
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 12-dimensional archetypal scoring → ElementVector.
 * Full dimension lookup tables to be ported from iOS `TagEngine.swift`.
 * This shell ranks by precomputed `elementScores` cosine similarity so
 * Tonight/UI can be wired before full table parity lands.
 */
@Singleton
class TagEngine @Inject constructor() {

    fun rankSounds(
        nightlyScore: ElementVector,
        sounds: List<Sound>,
        limit: Int = 12,
    ): List<RankedSound> {
        return sounds
            .map { sound ->
                RankedSound(
                    sound = sound,
                    score = nightlyScore.cosineSimilarity(sound.elementScores),
                )
            }
            .sorted()
            .take(limit)
    }

    /**
     * Placeholder: recompute vector from tags once lookup tables are ported.
     * Until then, prefer `sound.elementScores` from the manifest.
     */
    fun calculateTagVector(tags: SoundTags): ElementVector {
        // TODO(port): full 12-dimension weighted tables from iOS TagEngine
        return ElementVector.ZERO
    }
}
