package com.astrosleep.app.ui.onboarding

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.astrosleep.app.R
import com.astrosleep.app.ui.theme.SeaBiolume
import com.astrosleep.app.ui.theme.SeaFaint
import com.astrosleep.app.ui.theme.SeaGlassCard
import com.astrosleep.app.ui.theme.SeaMuted
import com.astrosleep.app.ui.theme.SeaPrimaryButton
import com.astrosleep.app.ui.theme.SeaText
import com.astrosleep.app.ui.theme.SeaVoid
import com.astrosleep.app.ui.theme.rememberSeaEnterProgress
import com.astrosleep.app.ui.theme.seaEnter
import java.util.Calendar
import java.util.TimeZone

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
    var knowsBirthTime by remember { mutableStateOf(true) }
    var lat by remember { mutableStateOf("40.7128") }
    var lng by remember { mutableStateOf("-74.0060") }
    var tzId by remember { mutableStateOf(TimeZone.getDefault().id) }

    val enter = rememberSeaEnterProgress()
    val fieldColors = OutlinedTextFieldDefaults.colors(
        focusedTextColor = SeaText,
        unfocusedTextColor = SeaText,
        focusedBorderColor = SeaBiolume,
        unfocusedBorderColor = Color(0xFF2A3650),
        focusedLabelColor = SeaBiolume,
        unfocusedLabelColor = SeaMuted,
        cursorColor = SeaBiolume,
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(SeaVoid, Color(0xFF0B1220))))
            .verticalScroll(rememberScrollState())
            .padding(20.dp)
            .seaEnter(enter),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            painter = painterResource(R.drawable.logo_astrosleep),
            contentDescription = "AstroSleep",
        )
        Text("Welcome to AstroSleep", style = MaterialTheme.typography.headlineMedium, color = SeaText)

        SeaGlassCard {
            Text(
                "Your birth data stays on this device. Charts never leave the phone. " +
                    "Timezone is applied when computing local birth time.",
                style = MaterialTheme.typography.bodyMedium,
                color = SeaMuted,
            )
        }

        OutlinedTextField(
            value = name,
            onValueChange = { name = it },
            label = { Text("Name") },
            modifier = Modifier.fillMaxWidth(),
            colors = fieldColors,
            singleLine = true,
        )
        OutlinedTextField(
            value = birthCity,
            onValueChange = { birthCity = it },
            label = { Text("Birth city") },
            modifier = Modifier.fillMaxWidth(),
            colors = fieldColors,
            singleLine = true,
        )

        Text("Birth date (Y / M / D)", style = MaterialTheme.typography.labelLarge, color = SeaFaint)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
            OutlinedTextField(
                value = year, onValueChange = { year = it }, label = { Text("Year") },
                modifier = Modifier.weight(1f), colors = fieldColors, singleLine = true,
            )
            OutlinedTextField(
                value = month, onValueChange = { month = it }, label = { Text("Month") },
                modifier = Modifier.weight(1f), colors = fieldColors, singleLine = true,
            )
            OutlinedTextField(
                value = day, onValueChange = { day = it }, label = { Text("Day") },
                modifier = Modifier.weight(1f), colors = fieldColors, singleLine = true,
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("I know my birth time", color = SeaText, style = MaterialTheme.typography.bodyMedium)
            Switch(checked = knowsBirthTime, onCheckedChange = { knowsBirthTime = it })
        }
        if (knowsBirthTime) {
            Text("Birth time 24h (local)", style = MaterialTheme.typography.labelLarge, color = SeaFaint)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                OutlinedTextField(
                    value = hour, onValueChange = { hour = it }, label = { Text("Hour") },
                    modifier = Modifier.weight(1f), colors = fieldColors, singleLine = true,
                )
                OutlinedTextField(
                    value = minute, onValueChange = { minute = it }, label = { Text("Min") },
                    modifier = Modifier.weight(1f), colors = fieldColors, singleLine = true,
                )
            }
        } else {
            Text(
                "Ascendant/houses use noon default when birth time is unknown.",
                style = MaterialTheme.typography.bodySmall,
                color = SeaFaint,
            )
        }

        OutlinedTextField(
            value = tzId,
            onValueChange = { tzId = it },
            label = { Text("Timezone ID") },
            modifier = Modifier.fillMaxWidth(),
            colors = fieldColors,
            singleLine = true,
            supportingText = {
                Text("e.g. America/New_York · defaults to device zone", color = SeaFaint)
            },
        )

        Text("Coordinates (geocoder next)", style = MaterialTheme.typography.labelLarge, color = SeaFaint)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
            OutlinedTextField(
                value = lat, onValueChange = { lat = it }, label = { Text("Lat") },
                modifier = Modifier.weight(1f), colors = fieldColors, singleLine = true,
            )
            OutlinedTextField(
                value = lng, onValueChange = { lng = it }, label = { Text("Lng") },
                modifier = Modifier.weight(1f), colors = fieldColors, singleLine = true,
            )
        }

        errorMessage?.let {
            Text(it, color = Color(0xFFFF453A), style = MaterialTheme.typography.bodySmall)
        }

        Spacer(Modifier.height(4.dp))

        if (isLoading) {
            CircularProgressIndicator(color = SeaBiolume)
        } else {
            SeaPrimaryButton(
                text = "Compute my chart",
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    val zone = try {
                        TimeZone.getTimeZone(tzId.ifBlank { TimeZone.getDefault().id })
                    } catch (_: Throwable) {
                        TimeZone.getDefault()
                    }
                    val cal = Calendar.getInstance(zone).apply {
                        set(Calendar.YEAR, year.toIntOrNull() ?: 1990)
                        set(Calendar.MONTH, (month.toIntOrNull() ?: 6) - 1)
                        set(Calendar.DAY_OF_MONTH, day.toIntOrNull() ?: 15)
                        set(Calendar.HOUR_OF_DAY, hour.toIntOrNull() ?: 12)
                        set(Calendar.MINUTE, minute.toIntOrNull() ?: 0)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                    }
                    val hasTime = knowsBirthTime && hour.isNotBlank() && minute.isNotBlank()
                    if (!knowsBirthTime) {
                        // Noon local for date-only path (engine uses null time → noon JD fraction)
                        cal.set(Calendar.HOUR_OF_DAY, 12)
                        cal.set(Calendar.MINUTE, 0)
                    }
                    onComplete(
                        name.ifBlank { "Dreamer" },
                        cal.timeInMillis,
                        if (hasTime) cal.timeInMillis else null,
                        lat.toDoubleOrNull() ?: 0.0,
                        lng.toDoubleOrNull() ?: 0.0,
                        birthCity.ifBlank { "Unknown" },
                    )
                },
            )
        }
    }
}
