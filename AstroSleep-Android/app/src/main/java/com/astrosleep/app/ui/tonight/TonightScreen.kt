package com.astrosleep.app.ui.tonight

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.astrosleep.app.state.AppUiState
import com.astrosleep.app.ui.theme.SeaBiolume
import com.astrosleep.app.ui.theme.SeaFaint
import com.astrosleep.app.ui.theme.SeaGlassCard
import com.astrosleep.app.ui.theme.SeaMuted
import com.astrosleep.app.ui.theme.SeaPrimaryButton
import com.astrosleep.app.ui.theme.SeaSecondaryButton
import com.astrosleep.app.ui.theme.SeaText
import com.astrosleep.app.ui.theme.SeaVoid
import com.astrosleep.app.ui.theme.rememberSeaEnterProgress
import com.astrosleep.app.ui.theme.seaEnter

@Composable
fun TonightScreen(
    state: AppUiState,
    onGenerate: () -> Unit,
    onPlay: () -> Unit,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onStop: () -> Unit,
) {
    val enter = rememberSeaEnterProgress()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(SeaVoid, Color(0xFF0B1220)),
                ),
            )
            .verticalScroll(rememberScrollState())
            .padding(20.dp)
            .seaEnter(enter),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(
            text = "Good night${state.profile?.name?.takeIf { it.isNotBlank() }?.let { ", $it" } ?: ""}",
            style = MaterialTheme.typography.headlineMedium,
            color = SeaText,
        )
        Text(
            "Ready to direct your subconscious tonight?",
            style = MaterialTheme.typography.bodyMedium,
            color = SeaMuted,
        )

        val score = state.nightlyScore
        SeaGlassCard {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                if (score == null) {
                    Text("Computing tonight's sky…", color = SeaMuted)
                    Spacer(Modifier.height(8.dp))
                    LinearProgressIndicator(
                        modifier = Modifier.fillMaxWidth(),
                        color = SeaBiolume,
                        trackColor = Color(0xFF2A3650),
                    )
                } else {
                    Text(
                        "Moon: ${score.moonPhase.displayName}",
                        style = MaterialTheme.typography.titleMedium,
                        color = SeaBiolume,
                    )
                    Text("Dominant: ${score.dominantElement.displayName}", color = SeaText)
                    Text(
                        "F ${"%.1f".format(score.elementScore.fire)}  " +
                            "E ${"%.1f".format(score.elementScore.earth)}  " +
                            "A ${"%.1f".format(score.elementScore.air)}  " +
                            "W ${"%.1f".format(score.elementScore.water)}",
                        style = MaterialTheme.typography.bodyLarge,
                        color = SeaMuted,
                    )
                    score.topTransit?.let {
                        Text(
                            "Top transit: ${it.planet.displayName} ${it.aspectType.displayName} natal ${it.natalPlanet.displayName}",
                            style = MaterialTheme.typography.bodySmall,
                            color = SeaFaint,
                        )
                    }
                }
            }
        }

        state.activeCombo?.let { combo ->
            SeaGlassCard {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(combo.name, style = MaterialTheme.typography.titleMedium, color = SeaText)
                    Text(
                        "${combo.layerCount} layers · ${state.currentTier.displayName}" +
                            (state.personalFingerprint?.let { " · fp ${it.toString(16).take(8)}" } ?: ""),
                        color = SeaMuted,
                    )
                    combo.layers.forEach { layer ->
                        Text(
                            "• ${layer.soundId} @ ${"%.0f".format(layer.volume * 100)}%" +
                                " · ${"%.2f".format(layer.playbackSpeed)}x",
                            color = SeaMuted,
                        )
                    }
                    if (state.isPlaying) {
                        Spacer(Modifier.height(4.dp))
                        Text("Playing · lockscreen controls active", color = SeaBiolume, style = MaterialTheme.typography.labelMedium)
                    }
                }
            }
        }

        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.fillMaxWidth(),
        ) {
            SeaSecondaryButton(text = "Generate", onClick = onGenerate)
            if (state.isPlaying) {
                SeaPrimaryButton(text = "Pause", onClick = onPause)
                SeaSecondaryButton(text = "Stop", onClick = onStop)
            } else {
                SeaPrimaryButton(
                    text = "Begin session",
                    onClick = onPlay,
                )
                if (state.activeCombo != null) {
                    SeaSecondaryButton(text = "Resume", onClick = onResume)
                }
            }
        }

        state.errorMessage?.let {
            SeaGlassCard {
                Text(it, color = Color(0xFFFF453A), style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}
