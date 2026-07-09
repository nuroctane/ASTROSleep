package com.astrosleep.app.ui.sounds

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.unit.dp
import com.astrosleep.app.state.AppViewModel

@Composable
fun SoundsScreen(viewModel: AppViewModel) {
    val sounds = remember { viewModel.allSounds() }

    Column {
        Text("Sound Library", style = MaterialTheme.typography.headlineSmall)
        Text(
            "${sounds.size} sounds · 12-dimensional tags",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(sounds, key = { it.id }) { sound ->
                Card {
                    Column {
                        Text(sound.name, style = MaterialTheme.typography.titleMedium)
                        Text(
                            "${sound.tags.domain} · ${sound.tags.celestial} · ${sound.tags.archetype}",
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                }
            }
        }
    }
}
