package com.astrosleep.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val Accent = Color(0xFF5856D6)
private val NightBg = Color(0xFF0B0B1A)

private val DarkColors = darkColorScheme(
    primary = Accent,
    secondary = Color(0xFF7D7AFF),
    background = NightBg,
    surface = Color(0xFF141428),
    onPrimary = Color.White,
    onBackground = Color(0xFFE8E8F0),
    onSurface = Color(0xFFE8E8F0),
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
