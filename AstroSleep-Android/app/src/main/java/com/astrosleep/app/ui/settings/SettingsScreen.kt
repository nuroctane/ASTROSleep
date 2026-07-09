package com.astrosleep.app.ui.settings

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.astrosleep.app.R
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
fun SettingsScreen(
    state: AppUiState,
    onRestore: () -> Unit,
    onSignInEmail: (String) -> Unit = {},
    onSignOut: () -> Unit = {},
    localUserId: String? = null,
    authStatusMessage: String? = null,
) {
    val enter = rememberSeaEnterProgress()
    var email by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(SeaVoid, Color(0xFF0B1220))))
            .verticalScroll(rememberScrollState())
            .padding(20.dp)
            .seaEnter(enter),
        verticalArrangement = Arrangement.spacedBy(14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            painter = painterResource(R.drawable.logo_astrosleep),
            contentDescription = "AstroSleep",
        )
        Text("Settings", style = MaterialTheme.typography.headlineSmall, color = SeaText)

        SeaGlassCard {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("Profile", style = MaterialTheme.typography.titleSmall, color = SeaBiolume)
                Text("Name: ${state.profile?.name ?: "—"}", color = SeaText)
                Text("Birth city: ${state.profile?.birthCity ?: "—"}", color = SeaMuted)
                Text("Tier: ${state.currentTier.displayName}", color = SeaText)
                Text(
                    "Birth chart data stays in on-device Room only — never uploaded with auth.",
                    style = MaterialTheme.typography.bodySmall,
                    color = SeaFaint,
                )
            }
        }

        SeaGlassCard {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                Text("Account", style = MaterialTheme.typography.titleSmall, color = SeaBiolume)
                Text(
                    "Local id: ${localUserId?.take(8) ?: "—"}…",
                    style = MaterialTheme.typography.bodySmall,
                    color = SeaFaint,
                )
                Text(
                    "Email / Google link Supabase when keys are configured. Until then, email is stored locally for restore identity.",
                    style = MaterialTheme.typography.bodySmall,
                    color = SeaMuted,
                )
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Email") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = SeaText,
                        unfocusedTextColor = SeaText,
                        focusedBorderColor = SeaBiolume,
                        unfocusedBorderColor = Color(0xFF2A3650),
                        focusedLabelColor = SeaBiolume,
                        unfocusedLabelColor = SeaMuted,
                        cursorColor = SeaBiolume,
                    ),
                )
                SeaPrimaryButton(
                    text = "Save email identity",
                    onClick = { if (email.isNotBlank()) onSignInEmail(email.trim()) },
                    enabled = email.isNotBlank(),
                    modifier = Modifier.fillMaxWidth(),
                )
                SeaSecondaryButton(
                    text = "Rotate local session",
                    onClick = onSignOut,
                    modifier = Modifier.fillMaxWidth(),
                )
                authStatusMessage?.let {
                    Text(it, color = SeaBiolume, style = MaterialTheme.typography.bodySmall)
                }
            }
        }

        SeaGlassCard {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                Text("Subscription", style = MaterialTheme.typography.titleSmall, color = SeaBiolume)
                Text(
                    "Play Billing via RevenueCat when API key is set. Restore re-reads entitlements.",
                    style = MaterialTheme.typography.bodySmall,
                    color = SeaMuted,
                )
                SeaPrimaryButton(
                    text = "Restore purchases",
                    onClick = onRestore,
                    modifier = Modifier.fillMaxWidth(),
                )
                SeaSecondaryButton(
                    text = "Manage in Play Store",
                    onClick = onRestore, // opens restore path; full manage deep-link when RC configured
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }

        Text(
            "Digital Sea · Emil/Apple motion · Liquid Glass family",
            style = MaterialTheme.typography.labelSmall,
            color = SeaFaint,
        )
    }
}
