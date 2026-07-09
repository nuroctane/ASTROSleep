package com.astrosleep.app.ui.paywall

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable

@Composable
fun PaywallDialog(
    trigger: String,
    onDismiss: () -> Unit,
    onRestore: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Unlock AstroSleep") },
        text = {
            Text(
                "This feature needs a paid plan ($trigger).\n" +
                    "Free: 2 layers · Subscription/Pro: up to 7 layers, custom voice, backup.",
            )
        },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("Not now") }
        },
        dismissButton = {
            TextButton(onClick = {
                onRestore()
                onDismiss()
            }) { Text("Restore Purchases") }
        },
    )
}
