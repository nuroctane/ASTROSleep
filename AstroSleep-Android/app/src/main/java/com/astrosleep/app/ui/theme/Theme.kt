package com.astrosleep.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Digital Sea tokens — repo DESIGN.md / emilkowalski/skills
// Public Sea* colors live in SeaSurfaces.kt; keep scheme locals private-prefixed.
private val Accent = Color(0xFF5856D6)
private val Biolume = Color(0xFF5AC8FA)
private val NightBg = Color(0xFF070B14)
private val Field = Color(0xFF0B1220)
private val Surface = Color(0xFF121A2B)
private val OnSea = Color(0xFFE8EEF8)

private val DarkColors = darkColorScheme(
    primary = Accent,
    secondary = Biolume,
    tertiary = Biolume,
    background = NightBg,
    surface = Surface,
    surfaceVariant = Field,
    surfaceContainer = Surface,
    surfaceContainerHigh = Color(0xFF1A2438),
    onPrimary = Color.White,
    onSecondary = NightBg,
    onBackground = OnSea,
    onSurface = OnSea,
    onSurfaceVariant = Color(0xFF9AA8C0),
    outline = Color(0xFF2A3650),
    outlineVariant = Color(0x22FFFFFF),
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
    darkTheme: Boolean = true, // sleep product defaults to night
    content: @Composable () -> Unit,
) {
    // Prefer dark Digital Sea always for product feel; allow system light only if explicitly false.
    val useDark = if (darkTheme) true else isSystemInDarkTheme()
    MaterialTheme(
        colorScheme = if (useDark) DarkColors else LightColors,
        content = content,
    )
}
