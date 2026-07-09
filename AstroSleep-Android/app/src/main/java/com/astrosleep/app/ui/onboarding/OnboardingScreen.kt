package com.astrosleep.app.ui.onboarding

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.astrosleep.app.R
import java.util.Calendar

@Composable
fun OnboardingScreen(
    isLoading: Boolean,
    errorMessage: String?,
    onComplete: (
        name: String,
        birthDateEpochMs: Long,
        birthTimeEpochMs: Long?,
        lat: Double,
        lng: Double,
        city: String,
    ) -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var birthCity by remember { mutableStateOf("") }
    var year by remember { mutableStateOf("1990") }
    var month by remember { mutableStateOf("6") }
    var day by remember { mutableStateOf("15") }
    var hour by remember { mutableStateOf("12") }
    var minute by remember { mutableStateOf("0") }
    var lat by remember { mutableStateOf("40.7128") }
    var lng by remember { mutableStateOf("-74.0060") }

    Column(
        verticalArrangement = Arrangement.Top,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            painter = painterResource(R.drawable.logo_astrosleep),
            contentDescription = "AstroSleep",
        )
        Text("Welcome to AstroSleep", style = MaterialTheme.typography.headlineMedium)
        Text(
            "Your birth data stays on this device. Never uploaded.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        OutlinedTextField(
            value = name,
            onValueChange = { name = it },
            label = { Text("Name") },
        )
        OutlinedTextField(
            value = birthCity,
            onValueChange = { birthCity = it },
            label = { Text("Birth city") },
        )
        Text("Birth date (Y / M / D)", style = MaterialTheme.typography.labelLarge)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(value = year, onValueChange = { year = it }, label = { Text("Year") })
            OutlinedTextField(value = month, onValueChange = { month = it }, label = { Text("Month") })
            OutlinedTextField(value = day, onValueChange = { day = it }, label = { Text("Day") })
        }
        Text("Birth time 24h", style = MaterialTheme.typography.labelLarge)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(value = hour, onValueChange = { hour = it }, label = { Text("Hour") })
            OutlinedTextField(value = minute, onValueChange = { minute = it }, label = { Text("Min") })
        }
        Text("Coordinates (until geocoder)", style = MaterialTheme.typography.labelLarge)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(value = lat, onValueChange = { lat = it }, label = { Text("Lat") })
            OutlinedTextField(value = lng, onValueChange = { lng = it }, label = { Text("Lng") })
        }

        errorMessage?.let {
            Text(it, color = MaterialTheme.colorScheme.error)
        }

        if (isLoading) {
            CircularProgressIndicator()
        } else {
            Button(
                onClick = {
                    val cal = Calendar.getInstance().apply {
                        set(Calendar.YEAR, year.toIntOrNull() ?: 1990)
                        set(Calendar.MONTH, (month.toIntOrNull() ?: 6) - 1)
                        set(Calendar.DAY_OF_MONTH, day.toIntOrNull() ?: 15)
                        set(Calendar.HOUR_OF_DAY, hour.toIntOrNull() ?: 12)
                        set(Calendar.MINUTE, minute.toIntOrNull() ?: 0)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                    }
                    val hasTime = hour.isNotBlank() && minute.isNotBlank()
                    onComplete(
                        name.ifBlank { "Dreamer" },
                        cal.timeInMillis,
                        if (hasTime) cal.timeInMillis else null,
                        lat.toDoubleOrNull() ?: 0.0,
                        lng.toDoubleOrNull() ?: 0.0,
                        birthCity.ifBlank { "Unknown" },
                    )
                },
            ) {
                Text("Compute my chart")
            }
        }
    }
}
