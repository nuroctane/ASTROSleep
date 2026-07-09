package com.astrosleep.app.ui.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
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

val SeaVoid = Color(0xFF070B14)
val SeaAccent = Color(0xFF5856D6)
val SeaBiolume = Color(0xFF5AC8FA)
