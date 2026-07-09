package com.astrosleep.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.material3.Surface
import com.astrosleep.app.service.RevenueCatService
import com.astrosleep.app.ui.AstroSleepRoot
import com.astrosleep.app.ui.theme.AstroSleepTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var revenueCat: RevenueCatService

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        revenueCat.setActivityProvider { this }
        setContent {
            AstroSleepTheme {
                Surface {
                    AstroSleepRoot()
                }
            }
        }
    }
}
