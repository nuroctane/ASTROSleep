package com.astrosleep.app.ui.library

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.astrosleep.app.state.AppViewModel
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
fun LibraryScreen(viewModel: AppViewModel) {
    val state by viewModel.ui.collectAsStateWithLifecycle()
    val enter = rememberSeaEnterProgress()
    LaunchedEffect(Unit) { viewModel.refreshLibrary() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(SeaVoid, Color(0xFF0B1220))))
            .padding(20.dp)
            .seaEnter(enter),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("Library", style = MaterialTheme.typography.headlineSmall, color = SeaText)
        Text(
            "${state.savedCombos.size} saved · ${state.currentTier.displayName} " +
                "(max ${if (state.currentTier.maxPlaylists == Int.MAX_VALUE) "∞" else state.currentTier.maxPlaylists})",
            style = MaterialTheme.typography.bodySmall,
            color = SeaMuted,
        )

        state.activeCombo?.let { active ->
            SeaGlassCard {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                    Text("Current session", style = MaterialTheme.typography.titleSmall, color = SeaBiolume)
                    Text(active.name, color = SeaText)
                    Text("${active.layerCount} layers", color = SeaMuted)
                    SeaPrimaryButton(
                        text = "Save to library",
                        onClick = { viewModel.saveActiveCombo() },
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
            }
        }

        if (state.savedCombos.isEmpty()) {
            SeaGlassCard {
                Text(
                    "Create your first combo from Tonight or Sounds, then save it here.\nRoom persistence is ready.",
                    color = SeaMuted,
                )
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                items(state.savedCombos, key = { it.id }) { combo ->
                    SeaGlassCard {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.fillMaxWidth()) {
                            Text(combo.name, style = MaterialTheme.typography.titleMedium, color = SeaText)
                            Text(
                                "${combo.layerCount} layers" +
                                    if (combo.isReadOnly) " · read-only" else "",
                                color = SeaMuted,
                            )
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                SeaPrimaryButton(
                                    text = "Play",
                                    onClick = { viewModel.playSavedCombo(combo) },
                                )
                                SeaSecondaryButton(
                                    text = "Delete",
                                    onClick = { viewModel.deleteCombo(combo.id) },
                                )
                            }
                        }
                    }
                }
            }
        }

        Text(
            "Birth data never leaves the device. Combos stay local.",
            style = MaterialTheme.typography.labelSmall,
            color = SeaFaint,
        )
    }
}
