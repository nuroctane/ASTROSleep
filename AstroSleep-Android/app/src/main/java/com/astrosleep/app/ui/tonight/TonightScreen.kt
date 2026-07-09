package com.astrosleep.app.ui.tonight

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.astrosleep.app.state.AppUiState
import com.astrosleep.app.ui.theme.SeaAccent
import com.astrosleep.app.ui.theme.SeaBiolume
import com.astrosleep.app.ui.theme.SeaGlassCard
import com.astrosleep.app.ui.theme.SeaVoid

@Composable
fun TonightScreen(
    state: AppUiState,
    onGenerate: () -> Unit,
    onPlay: () -> Unit,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onStop: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(SeaVoid, Color(0xFF0B1220)),
                ),
            )
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(
            text = "Good night${state.profile?.name?.takeIf { it.isNotBlank() }?.let { ", $it" } ?: ""}",
            style = MaterialTheme.typography.headlineMedium,
            color = Color(0xFFE8EEF8),
        )
        Text(
            "Ready to direct your subconscious tonight?",
            style = MaterialTheme.typography.bodyMedium,
            color = Color(0xFF9AA8C0),
        )

        val score = state.nightlyScore
        SeaGlassCard {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                if (score == null) {
                    Text("Computing tonight's sky…", color = Color(0xFF9AA8C0))
                } else {
                    Text(
                        "Moon: ${score.moonPhase.displayName}",
                        style = MaterialTheme.typography.titleMedium,
                        color = SeaBiolume,
                    )
                    Text("Dominant: ${score.dominantElement.displayName}", color = Color(0xFFE8EEF8))
                    Text(
                        "F ${"%.1f".format(score.elementScore.fire)}  " +
                            "E ${"%.1f".format(score.elementScore.earth)}  " +
                            "A ${"%.1f".format(score.elementScore.air)}  " +
                            "W ${"%.1f".format(score.elementScore.water)}",
                        style = MaterialTheme.typography.bodyLarge,
                        color = Color(0xFF9AA8C0),
                    )
                    score.topTransit?.let {
                        Text(
                            "Top transit: ${it.planet.displayName} ${it.aspectType.displayName} natal ${it.natalPlanet.displayName}",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color(0xFF6B7A94),
                        )
                    }
                }
            }
        }

        state.activeCombo?.let { combo ->
            SeaGlassCard {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(combo.name, style = MaterialTheme.typography.titleMedium, color = Color(0xFFE8EEF8))
                    Text(
                        "${combo.layerCount} layers · ${state.currentTier.displayName}" +
                            (state.personalFingerprint?.let { " · fp ${it.toString(16).take(8)}" } ?: ""),
                        color = Color(0xFF9AA8C0),
                    )
                    combo.layers.forEach { layer ->
                        Text(
                            "• ${layer.soundId} @ ${"%.0f".format(layer.volume * 100)}%" +
                                " · ${"%.2f".format(layer.playbackSpeed)}x",
                            color = Color(0xFF9AA8C0),
                        )
                    }
                }
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = onGenerate) { Text("Generate") }
            if (state.isPlaying) {
                Button(
                    onClick = onPause,
                    colors = ButtonDefaults.buttonColors(containerColor = SeaAccent),
                ) { Text("Pause") }
            } else {
                Button(
                    onClick = {
                        if (state.activeCombo == null) onGenerate()
                        onPlay()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = SeaAccent),
                ) { Text("Begin session") }
            }
            if (state.isPlaying) {
                OutlinedButton(onClick = onStop) { Text("Stop") }
            }
            if (!state.isPlaying && state.activeCombo != null) {
                OutlinedButton(onClick = onResume) { Text("Resume") }
            }
        }
    }
}
