package com.astrosleep.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.astrosleep.app.ui.AstroSleepRoot
import com.astrosleep.app.ui.theme.AstroSleepTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            AstroSleepTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    AstroSleepRoot()
                }
            }
        }
    }
}
