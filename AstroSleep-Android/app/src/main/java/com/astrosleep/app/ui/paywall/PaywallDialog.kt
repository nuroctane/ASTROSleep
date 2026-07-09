package com.astrosleep.app.ui.paywall

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.astrosleep.app.ui.theme.SeaBiolume
import com.astrosleep.app.ui.theme.SeaMuted
import com.astrosleep.app.ui.theme.SeaPrimaryButton
import com.astrosleep.app.ui.theme.SeaSecondaryButton
import com.astrosleep.app.ui.theme.SeaText

@Composable
fun PaywallDialog(
    trigger: String,
    onDismiss: () -> Unit,
    onRestore: () -> Unit,
    onPurchase: () -> Unit = {},
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = Color(0xFF121A2B),
        titleContentColor = SeaText,
        textContentColor = SeaMuted,
        title = { Text("Unlock AstroSleep") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    "This feature needs a paid plan ($trigger).",
                    style = MaterialTheme.typography.bodyMedium,
                )
                Text("Free · 2 layers", color = SeaMuted, style = MaterialTheme.typography.bodySmall)
                Text(
                    "Subscription / Lifetime · up to 7 layers, custom voice, backup, future features",
                    color = SeaBiolume,
                    style = MaterialTheme.typography.bodySmall,
                )
                Text(
                    "Purchases via Google Play + RevenueCat when configured. Restore always available.",
                    color = SeaMuted,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        },
        confirmButton = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                SeaPrimaryButton(
                    text = "Continue to purchase",
                    onClick = {
                        onPurchase()
                    },
                    modifier = Modifier.fillMaxWidth(),
                )
                SeaSecondaryButton(
                    text = "Restore purchases",
                    onClick = {
                        onRestore()
                        onDismiss()
                    },
                    modifier = Modifier.fillMaxWidth(),
                )
                SeaSecondaryButton(
                    text = "Not now",
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        dismissButton = {},
    )
}
