package com.astrosleep.app.ui.settings

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.astrosleep.app.R
import com.astrosleep.app.state.AppUiState

@Composable
fun SettingsScreen(
    state: AppUiState,
    onRestore: () -> Unit,
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            painter = painterResource(R.drawable.logo_astrosleep),
            contentDescription = "AstroSleep",
        )
        Text("Settings", style = MaterialTheme.typography.headlineSmall)
        Text("Profile: ${state.profile?.name ?: "—"}")
        Text("Birth city: ${state.profile?.birthCity ?: "—"}")
        Text("Tier: ${state.currentTier.displayName}")
        Text(
            "Birth data is stored only in local Room DB.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        OutlinedButton(onClick = onRestore) {
            Text("Restore Purchases")
        }
        Button(onClick = { }, enabled = false) {
            Text("Manage subscription (coming soon)")
        }
    }
}
