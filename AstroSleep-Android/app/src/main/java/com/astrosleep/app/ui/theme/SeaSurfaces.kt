package com.astrosleep.app.ui.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Digital Sea “glass” card — translucent gradient + hairline edge (Material 3 dark). */
@Composable
fun SeaGlassCard(
    modifier: Modifier = Modifier,
    corner: Dp = 16.dp,
    contentPadding: Dp = 16.dp,
    content: @Composable BoxScope.() -> Unit,
) {
    val shape = RoundedCornerShape(corner)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(
                Brush.linearGradient(
                    listOf(
                        Color(0x18FFFFFF),
                        Color(0xCC121A2B),
                        Color(0xE60B1220),
                    ),
                ),
            )
            .border(1.dp, Color(0x22FFFFFF), shape)
            .padding(contentPadding),
        content = content,
    )
}

/** Primary pill CTA — accent fill + Material press (paired with scale via seaPressable wrappers when needed). */
@Composable
fun SeaPrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.graphicsLayer { /* press handled by M3 ripple; scale via parent if needed */ },
        colors = ButtonDefaults.buttonColors(
            containerColor = SeaAccent,
            contentColor = Color.White,
            disabledContainerColor = SeaAccent.copy(alpha = 0.35f),
            disabledContentColor = Color.White.copy(alpha = 0.6f),
        ),
        shape = RoundedCornerShape(999.dp),
    ) {
        Text(text, style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
fun SeaSecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier,
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = Color(0xFFE8EEF8),
        ),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF2A3650)),
        shape = RoundedCornerShape(999.dp),
    ) {
        Text(text, style = MaterialTheme.typography.labelLarge)
    }
}

val SeaVoid = Color(0xFF070B14)
val SeaField = Color(0xFF0B1220)
val SeaSurface = Color(0xFF121A2B)
val SeaAccent = Color(0xFF5856D6)
val SeaBiolume = Color(0xFF5AC8FA)
val SeaText = Color(0xFFE8EEF8)
val SeaMuted = Color(0xFF9AA8C0)
val SeaFaint = Color(0xFF6B7A94)
