package com.astrosleep.app.ui.sounds

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.astrosleep.app.state.AppViewModel

@Composable
fun SoundsScreen(viewModel: AppViewModel) {
    val state by viewModel.ui.collectAsStateWithLifecycle()
    LaunchedEffect(state.profile?.id, state.nightlyScore) {
        viewModel.refreshRankedPreview()
    }

    val ranked = state.rankedPreview
    val sounds = remember { viewModel.allSounds() }
    val display = if (ranked.isNotEmpty()) {
        ranked.map { it.sound to it }
    } else {
        sounds.map { it to null }
    }

    Column {
        Text("Sound Library", style = MaterialTheme.typography.headlineSmall)
        Text(
            if (ranked.isNotEmpty()) {
                "${ranked.size} ranked for your chart · fp ${state.personalFingerprint?.toString(16)?.take(8) ?: "—"}"
            } else {
                "${sounds.size} sounds · generate Tonight to personalize"
            },
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(display, key = { it.first.id }) { (sound, rank) ->
                Card {
                    Column {
                        Text(
                            buildString {
                                append(sound.name)
                                rank?.let {
                                    append("  ·  ${"%.0f".format(it.matchPercentage)}%")
                                    it.suggestedRole?.let { r -> append("  ·  ${r.name}") }
                                }
                            },
                            style = MaterialTheme.typography.titleMedium,
                        )
                        Text(
                            "${sound.tags.domain} · ${sound.tags.celestial} · ${sound.tags.archetype}",
                            style = MaterialTheme.typography.bodySmall,
                        )
                        rank?.breakdown?.let { b ->
                            Text(
                                "N ${"%.1f".format(b.nightlyResonance)} · " +
                                    "Natal ${"%.1f".format(b.natalResonance)} · " +
                                    "Tags ${"%.1f".format(b.tagAffinity)} · " +
                                    "Tx ${"%.1f".format(b.transitResonance)}",
                                style = MaterialTheme.typography.labelSmall,
                            )
                        }
                    }
                }
            }
        }
    }
}
