package com.astrosleep.app.ui.tonight

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import com.astrosleep.app.state.AppUiState

@Composable
fun TonightScreen(
    state: AppUiState,
    onGenerate: () -> Unit,
    onPlay: () -> Unit,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onStop: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text(
            text = "Good night${state.profile?.name?.takeIf { it.isNotBlank() }?.let { ", $it" } ?: ""}",
            style = MaterialTheme.typography.headlineMedium,
        )

        val score = state.nightlyScore
        Card {
            Column {
                if (score == null) {
                    Text("Computing tonight's sky…")
                } else {
                    Text("Moon: ${score.moonPhase.displayName}", style = MaterialTheme.typography.titleMedium)
                    Text("Dominant: ${score.dominantElement.displayName}")
                    Text(
                        "F ${"%.1f".format(score.elementScore.fire)}  " +
                            "E ${"%.1f".format(score.elementScore.earth)}  " +
                            "A ${"%.1f".format(score.elementScore.air)}  " +
                            "W ${"%.1f".format(score.elementScore.water)}",
                        style = MaterialTheme.typography.bodyLarge,
                    )
                    score.topTransit?.let {
                        Text(
                            "Top transit: ${it.planet.displayName} ${it.aspectType.displayName} natal ${it.natalPlanet.displayName}",
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                }
            }
        }

        state.activeCombo?.let { combo ->
            Card {
                Column {
                    Text(combo.name, style = MaterialTheme.typography.titleMedium)
                    Text(
                        "${combo.layerCount} layers · ${state.currentTier.displayName}" +
                            (state.personalFingerprint?.let { " · fp ${it.toString(16).take(8)}" } ?: ""),
                    )
                    combo.layers.forEach { layer ->
                        Text(
                            "• ${layer.soundId} @ ${"%.0f".format(layer.volume * 100)}%" +
                                " · ${"%.2f".format(layer.playbackSpeed)}x",
                        )
                    }
                }
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = onGenerate) { Text("Generate") }
            if (state.isPlaying) {
                Button(onClick = onPause) { Text("Pause") }
            } else {
                Button(
                    onClick = {
                        if (state.activeCombo == null) onGenerate()
                        onPlay()
                    },
                ) { Text("Play") }
            }
        }
        if (state.isPlaying || state.activeCombo != null) {
            OutlinedButton(onClick = onStop) { Text("Stop") }
            if (!state.isPlaying && state.activeCombo != null) {
                Button(onClick = onResume) { Text("Resume") }
            }
        }
    }
}
