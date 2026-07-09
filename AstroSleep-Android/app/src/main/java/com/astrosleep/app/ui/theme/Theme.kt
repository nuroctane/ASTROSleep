package com.astrosleep.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Digital Sea tokens — Building & Projects/DESIGN.md
private val Accent = Color(0xFF5856D6)
private val Biolume = Color(0xFF5AC8FA)
private val NightBg = Color(0xFF070B14)
private val SeaField = Color(0xFF0B1220)
private val SeaSurface = Color(0xFF121A2B)

private val DarkColors = darkColorScheme(
    primary = Accent,
    secondary = Biolume,
    background = NightBg,
    surface = SeaSurface,
    surfaceVariant = SeaField,
    onPrimary = Color.White,
    onBackground = Color(0xFFE8EEF8),
    onSurface = Color(0xFFE8EEF8),
    outline = Color(0xFF2A3650),
)

private val LightColors = lightColorScheme(
    primary = Accent,
    secondary = Color(0xFF4A48B0),
    background = Color(0xFFF7F7FB),
    surface = Color.White,
    onPrimary = Color.White,
)

@Composable
fun AstroSleepTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        content = content,
    )
}
