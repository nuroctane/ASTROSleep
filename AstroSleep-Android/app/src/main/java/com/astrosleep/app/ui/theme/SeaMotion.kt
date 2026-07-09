package com.astrosleep.app.ui.theme

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.Role
import android.provider.Settings

/**
 * Emil / Apple motion tokens for Compose.
 * SoT: repo DESIGN.md · emilkowalski/skills (emil-design-eng + apple-design)
 */
object SeaMotion {
    /** Strong ease-out — instant feedback, soft landing. */
    val EaseOut = CubicBezierEasing(0.23f, 1f, 0.32f, 1f)
    val EaseInOut = CubicBezierEasing(0.77f, 0f, 0.175f, 1f)

    const val PressMs = 140
    const val UiMs = 200
    const val EnterMs = 220
    const val PressScale = 0.97f
    const val EnterScale = 0.95f
}

/** System reduce-motion (Settings → Accessibility → Remove animations). */
@Composable
fun rememberReduceMotion(): Boolean {
    val view = LocalView.current
    return remember(view) {
        try {
            Settings.Global.getFloat(
                view.context.contentResolver,
                Settings.Global.ANIMATOR_DURATION_SCALE,
                1f,
            ) == 0f
        } catch (_: Throwable) {
            false
        }
    }
}

/**
 * Press scale 0.97 (Emil). GPU transform only.
 * Use on any tappable surface that is not already a Material button with its own ripple-only feedback.
 */
fun Modifier.seaPressable(
    enabled: Boolean = true,
    onClick: () -> Unit,
    role: Role? = Role.Button,
): Modifier = composed {
    val reduce = rememberReduceMotion()
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale = remember { Animatable(1f) }

    LaunchedEffect(pressed, reduce, enabled) {
        val target = if (enabled && pressed && !reduce) SeaMotion.PressScale else 1f
        scale.animateTo(
            target,
            animationSpec = tween(
                durationMillis = if (reduce) 0 else SeaMotion.PressMs,
                easing = SeaMotion.EaseOut,
            ),
        )
    }

    this
        .graphicsLayer {
            scaleX = scale.value
            scaleY = scale.value
        }
        .clickable(
            enabled = enabled,
            interactionSource = interaction,
            indication = null,
            role = role,
            onClick = onClick,
        )
}

/** Soft enter: opacity + slight scale (never from 0). */
@Composable
fun rememberSeaEnterProgress(reduceMotion: Boolean = rememberReduceMotion()): Float {
    val progress = remember { Animatable(if (reduceMotion) 1f else 0f) }
    LaunchedEffect(reduceMotion) {
        if (reduceMotion) {
            progress.snapTo(1f)
        } else {
            progress.animateTo(
                1f,
                animationSpec = tween(SeaMotion.EnterMs, easing = SeaMotion.EaseOut),
            )
        }
    }
    return progress.value
}

fun Modifier.seaEnter(progress: Float): Modifier = graphicsLayer {
    val p = progress.coerceIn(0f, 1f)
    alpha = p
    val s = SeaMotion.EnterScale + (1f - SeaMotion.EnterScale) * p
    scaleX = s
    scaleY = s
}
