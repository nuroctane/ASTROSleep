package com.astrosleep.app.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LibraryMusic
import androidx.compose.material.icons.filled.NightsStay
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Waves
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.astrosleep.app.R
import com.astrosleep.app.state.AppViewModel
import com.astrosleep.app.ui.library.LibraryScreen
import com.astrosleep.app.ui.onboarding.OnboardingScreen
import com.astrosleep.app.ui.paywall.PaywallDialog
import com.astrosleep.app.ui.settings.SettingsScreen
import com.astrosleep.app.ui.sounds.SoundsScreen
import com.astrosleep.app.ui.tonight.TonightScreen

@Composable
fun AstroSleepRoot(
    viewModel: AppViewModel = hiltViewModel(),
) {
    val state by viewModel.ui.collectAsStateWithLifecycle()

    if (state.isLoading && state.profile == null && !state.hasCompletedOnboarding) {
        Box(contentAlignment = Alignment.Center) {
            Image(
                painter = painterResource(R.drawable.logo_astrosleep),
                contentDescription = "AstroSleep",
            )
        }
        return
    }

    if (!state.hasCompletedOnboarding) {
        OnboardingScreen(
            isLoading = state.isLoading,
            errorMessage = state.errorMessage,
            onComplete = { name, birthMs, timeMs, lat, lng, city ->
                viewModel.completeOnboarding(name, birthMs, timeMs, lat, lng, city)
            },
        )
        return
    }

    Scaffold(
        bottomBar = {
            NavigationBar {
                val tabs = listOf(
                    Triple(0, "Tonight", Icons.Default.NightsStay),
                    Triple(1, "Sounds", Icons.Default.Waves),
                    Triple(2, "Library", Icons.Default.LibraryMusic),
                    Triple(3, "Settings", Icons.Default.Settings),
                )
                tabs.forEach { (index, label, icon) ->
                    NavigationBarItem(
                        selected = state.selectedTab == index,
                        onClick = { viewModel.selectTab(index) },
                        icon = { Icon(icon, contentDescription = label) },
                        label = { Text(label) },
                    )
                }
            }
        },
    ) { _ ->
        when (state.selectedTab) {
            0 -> TonightScreen(
                state = state,
                onGenerate = { viewModel.autoGenerateCombo() },
                onPlay = { viewModel.startSession() },
                onPause = { viewModel.pauseSession() },
                onResume = { viewModel.resumeSession() },
                onStop = { viewModel.stopSession() },
            )
            1 -> SoundsScreen(viewModel = viewModel)
            2 -> LibraryScreen()
            else -> SettingsScreen(
                state = state,
                onRestore = { viewModel.restorePurchases() },
            )
        }
    }

    if (state.showPaywall) {
        PaywallDialog(
            trigger = state.paywallTrigger,
            onDismiss = { viewModel.dismissPaywall() },
            onRestore = { viewModel.restorePurchases() },
        )
    }
}
