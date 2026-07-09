package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.Aspect
import com.astrosleep.app.core.model.AspectarianEntry
import com.astrosleep.app.core.model.ChartPlacement
import com.astrosleep.app.core.model.Element
import com.astrosleep.app.core.model.ElementVector
import com.astrosleep.app.core.model.House
import com.astrosleep.app.core.model.Modality
import com.astrosleep.app.core.model.MoonPhase
import com.astrosleep.app.core.model.NatalChart
import com.astrosleep.app.core.model.NightlyScoreResult
import com.astrosleep.app.core.model.Planet
import com.astrosleep.app.core.model.Sign
import com.astrosleep.app.core.model.Stellium
import com.astrosleep.app.core.model.Transit
import java.util.Calendar
import java.util.TimeZone
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.abs
import kotlin.math.min

/**
 * Natal chart + transit scoring — port of iOS AstrologicalEngine.swift.
 * Sidereal 13-sign · Sharatan ayanamsha · simplified ephemeris (same as iOS).
 */
@Singleton
class AstrologicalEngine @Inject constructor() {

    /** Sharatan ayanamsha ≈ 24°06'18" */
    val sharatanAyanamsha: Double = 24.0 + 6.0 / 60.0 + 18.0 / 3600.0

    private val siderealYear: Double = 365.256363004
    private val synodicMonth: Double = 29.53058867

    fun computeNatalChart(
        birthDateEpochMs: Long,
        birthTimeEpochMs: Long?,
        lat: Double,
        lng: Double,
    ): NatalChart {
        val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            timeInMillis = birthDateEpochMs
        }
        val year = cal.get(Calendar.YEAR)
        val month = cal.get(Calendar.MONTH) + 1
        val day = cal.get(Calendar.DAY_OF_MONTH)

        // Merge birth time into fractional JD (was date-only).
        var dayFraction = 0.5 // noon default when time unknown
        val hasBirthTime = birthTimeEpochMs != null
        if (birthTimeEpochMs != null) {
            val tc = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
                timeInMillis = birthTimeEpochMs
            }
            val h = tc.get(Calendar.HOUR_OF_DAY).toDouble()
            val m = tc.get(Calendar.MINUTE).toDouble()
            val s = tc.get(Calendar.SECOND).toDouble()
            dayFraction = (h + m / 60.0 + s / 3600.0) / 24.0
        }
        val julianDay = julianDayFor(year, month, day) + dayFraction

        var placements = Planet.entries.map { planet ->
            simplifiedPlanetaryPosition(planet, julianDay, lat, lng)
        }

        val ascendant = if (hasBirthTime) computeAscendant(julianDay, lat, lng) else null
        if (ascendant != null) {
            placements = placements.map { p ->
                p.copy(house = houseFromLongitude(p.degree, ascendant))
            }
        }
        val aspects = computeAspects(placements)
        val stelliums = detectStelliums(placements)

        return NatalChart(
            computedAtEpochMs = System.currentTimeMillis(),
            placements = placements,
            ascendant = ascendant,
            mc = null,
            dominantElement = computeDominantElement(placements),
            dominantModality = computeDominantModality(placements),
            aspects = aspects,
            stelliums = stelliums,
            hasBirthTime = hasBirthTime,
        )
    }

    fun deriveBaseScore(chart: NatalChart): ElementVector {
        var score = ElementVector()

        chart.moonSign?.let { score = score + ElementVector.forSign(it) * 4.0 }
        chart.sunSign?.let { score = score + ElementVector.forSign(it) * 2.0 }
        chart.ascendant?.let { score = score + ElementVector.forSign(it) * 1.5 }
        chart.mercurySign?.let { score = score + ElementVector.forSign(it) * 1.0 }
        chart.venusSign?.let { score = score + ElementVector.forSign(it) * 1.5 }
        chart.marsSign?.let { score = score + ElementVector.forSign(it) * 1.0 }
        chart.jupiterSign?.let { score = score + ElementVector.forSign(it) * 0.8 }
        chart.saturnSign?.let { score = score + ElementVector.forSign(it) * 0.7 }
        chart.uranusSign?.let { score = score + ElementVector.forSign(it) * 0.5 }
        chart.neptuneSign?.let { score = score + ElementVector.forSign(it) * 0.8 }
        chart.plutoSign?.let { score = score + ElementVector.forSign(it) * 0.6 }
        chart.chironSign?.let { score = score + ElementVector.forSign(it) * 0.5 }
        chart.lilithSign?.let { score = score + ElementVector.forSign(it) * 0.4 }

        chart.northNode?.let { score[it.sign.element] = score[it.sign.element] + 0.6 }
        chart.southNode?.let { score[it.sign.element] = score[it.sign.element] + 0.4 }

        val dominantElement = score.dominant()
        score[dominantElement] = score[dominantElement] + 2.0

        when (chart.dominantModality) {
            Modality.FIXED -> score[Element.EARTH] = score[Element.EARTH] + 1.0
            Modality.CARDINAL -> score[Element.FIRE] = score[Element.FIRE] + 1.0
            Modality.MUTABLE -> score[Element.AIR] = score[Element.AIR] + 1.0
        }

        for (stellium in chart.stelliums) {
            score = score + ElementVector.forSign(stellium) * 1.2
        }

        if (chart.hasBirthTime) {
            chart.moonHouse?.let { score = score + ElementVector.forHouse(it) * 1.0 }
            chart.sunHouse?.let { score = score + ElementVector.forHouse(it) * 0.5 }
            for (house in House.entries) {
                val ruler = chart.houseRuler(house)
                chart.placement(ruler)?.sign?.let { sign ->
                    score = score + ElementVector.forSign(sign) * 0.3
                }
            }
        }

        return score.normalize(10.0)
    }

    fun calculateNightlyScore(
        baseScore: ElementVector,
        dateEpochMs: Long,
        natalChart: NatalChart,
        currentLat: Double = 0.0,
        currentLng: Double = 0.0,
        useCurrentLocation: Boolean = false,
    ): NightlyScoreResult {
        var score = baseScore.copy()

        val moonPhase = calculateMoonPhase(dateEpochMs)
        score = score + ElementVector.phaseDelta(moonPhase)

        val transitLat = if (useCurrentLocation) currentLat else 0.0
        val transitLng = if (useCurrentLocation) currentLng else 0.0

        val currentPlacements = simplifiedCurrentPlacements(dateEpochMs, transitLat, transitLng)
        val transits = calculateTransits(
            dateEpochMs = dateEpochMs,
            natalChart = natalChart,
            currentPlacements = currentPlacements,
            currentLat = transitLat,
            currentLng = transitLng,
            useCurrentLocation = useCurrentLocation,
        )

        for (transit in transits) {
            val delta = ElementVector.transitDelta(transit.planet, transit.aspectType) ?: continue
            val orbFactor = maxOf(0.0, 1.0 - (transit.orb / transit.aspectType.orb))
            score = score + delta * orbFactor
        }

        if (natalChart.hasBirthTime) {
            for (placement in currentPlacements) {
                val house = placement.house ?: continue
                val planetWeight = placement.planet.baseScoreWeight
                score = score + ElementVector.forHouse(house) * 0.5 * planetWeight
            }
        }

        val currentStelliumSigns = detectStelliums(currentPlacements)
        val stelliumList = mutableListOf<Stellium>()
        for (sign in currentStelliumSigns) {
            val planets = currentPlacements.filter { it.sign == sign }.map { it.planet }
            stelliumList.add(Stellium(sign = sign, planets = planets))
            score = score + ElementVector.forSign(sign) * 0.8
        }

        val normalized = score.normalize(10.0)
        return NightlyScoreResult(
            elementScore = normalized,
            moonPhase = moonPhase,
            activeTransits = transits,
            dominantElement = normalized.dominant(),
            topTransit = transits.maxByOrNull { it.strength },
            stelliums = stelliumList,
        )
    }

    fun calculateMoonPhase(dateEpochMs: Long): MoonPhase {
        // Known new moon: 2000-01-06 18:14 UTC
        val knownNewMoonEpochMs = 947_182_440_000L
        val secondsSinceNewMoon = (dateEpochMs - knownNewMoonEpochMs) / 1000.0
        val daysSinceNewMoon = secondsSinceNewMoon / 86400.0
        val phaseCycle = positiveMod(daysSinceNewMoon, synodicMonth) / synodicMonth

        return when {
            phaseCycle < 0.03 || phaseCycle >= 0.97 -> MoonPhase.NEW_MOON
            phaseCycle < 0.22 -> MoonPhase.WAXING_CRESCENT
            phaseCycle < 0.28 -> MoonPhase.FIRST_QUARTER
            phaseCycle < 0.47 -> MoonPhase.WAXING_GIBBOUS
            phaseCycle < 0.53 -> MoonPhase.FULL_MOON
            phaseCycle < 0.72 -> MoonPhase.WANING_GIBBOUS
            phaseCycle < 0.78 -> MoonPhase.LAST_QUARTER
            else -> MoonPhase.WANING_CRESCENT
        }
    }

    // ── Private helpers (iOS parity) ──────────────────────────────────────

    internal fun julianDayFor(year: Int, month: Int, day: Int): Double {
        val a = (14 - month) / 12
        val y = year + 4800 - a
        val m = month + 12 * a - 3
        return day.toDouble() +
            ((153 * m + 2) / 5).toDouble() +
            365.0 * y +
            (y / 4).toDouble() -
            (y / 100).toDouble() +
            (y / 400).toDouble() -
            32045.0
    }

    private fun simplifiedPlanetaryPosition(
        planet: Planet,
        julianDay: Double,
        lat: Double,
        lng: Double,
    ): ChartPlacement {
        val daysSinceEpoch = julianDay - 2451545.0
        var isRetrograde = false

        val longitude = when (planet) {
            Planet.SUN -> positiveMod(daysSinceEpoch * 360.0 / 365.25, 360.0)
            Planet.MOON -> positiveMod(daysSinceEpoch * 360.0 / 27.32, 360.0)
            Planet.MERCURY -> {
                isRetrograde = positiveMod(daysSinceEpoch, 116.0) < 21.0
                positiveMod(daysSinceEpoch * 360.0 / 87.97, 360.0)
            }
            Planet.VENUS -> {
                isRetrograde = positiveMod(daysSinceEpoch, 584.0) < 42.0
                positiveMod(daysSinceEpoch * 360.0 / 224.7, 360.0)
            }
            Planet.MARS -> {
                isRetrograde = positiveMod(daysSinceEpoch, 780.0) < 72.0
                positiveMod(daysSinceEpoch * 360.0 / 686.98, 360.0)
            }
            Planet.JUPITER -> positiveMod(daysSinceEpoch * 360.0 / 4332.59, 360.0)
            Planet.SATURN -> positiveMod(daysSinceEpoch * 360.0 / 10759.22, 360.0)
            Planet.URANUS -> positiveMod(daysSinceEpoch * 360.0 / 30685.4, 360.0)
            Planet.NEPTUNE -> positiveMod(daysSinceEpoch * 360.0 / 60189.0, 360.0)
            Planet.PLUTO -> positiveMod(daysSinceEpoch * 360.0 / 90560.0, 360.0)
            Planet.CHIRON -> positiveMod(daysSinceEpoch * 360.0 / 5068.0, 360.0)
            Planet.LILITH -> positiveMod(daysSinceEpoch * 360.0 / 6798.0, 360.0)
            Planet.NORTH_NODE -> positiveMod(125.0 - daysSinceEpoch * 360.0 / 6793.0, 360.0)
            Planet.SOUTH_NODE -> {
                val nn = positiveMod(125.0 - daysSinceEpoch * 360.0 / 6793.0, 360.0)
                positiveMod(nn + 180.0, 360.0)
            }
        }

        val siderealLongitude = positiveMod(longitude - sharatanAyanamsha + 360.0, 360.0)
        val sign = signFromLongitude(siderealLongitude)

        return ChartPlacement(
            planet = planet,
            sign = sign,
            house = null,
            degree = siderealLongitude,
            isRetrograde = isRetrograde,
        )
    }

    private fun computeAscendant(julianDay: Double, lat: Double, lng: Double): Sign {
        val lst = localSiderealTime(julianDay, lng)
        val ascLongitude = positiveMod(lst - 90.0 + 360.0, 360.0)
        return signFromLongitude(ascLongitude)
    }

    private fun localSiderealTime(julianDay: Double, longitude: Double): Double {
        val jd2000 = julianDay - 2451545.0
        val gmst = 280.46061837 + 360.98564736629 * jd2000
        return positiveMod(gmst + longitude + 360.0, 360.0)
    }

    /** Equal 13-sign sectors (360/13). Pisces is reachable. */
    private fun signFromLongitude(longitude: Double): Sign {
        val sector = 360.0 / Sign.entries.size
        val lon = positiveMod(longitude, 360.0)
        val index = min((lon / sector).toInt(), Sign.entries.lastIndex)
        return Sign.entries[index]
    }

    private fun houseFromLongitude(longitude: Double, ascendant: Sign?): House? {
        val asc = ascendant ?: return null
        val sector = 360.0 / 13.0
        val ascDegree = asc.index * sector
        val relativeDegree = positiveMod(longitude - ascDegree + 360.0, 360.0)
        val houseNumber = (relativeDegree / 30.0).toInt() + 1
        return House.fromNumber(houseNumber.coerceIn(1, 12))
    }

    private fun computeAspects(placements: List<ChartPlacement>): List<AspectarianEntry> {
        val aspects = mutableListOf<AspectarianEntry>()
        for (i in placements.indices) {
            for (j in (i + 1) until placements.size) {
                val p1 = placements[i]
                val p2 = placements[j]
                val diff = abs(p1.degree - p2.degree)
                val shortestDiff = min(diff, 360.0 - diff)
                for (aspect in Aspect.entries) {
                    if (abs(shortestDiff - aspect.angle) <= aspect.orb) {
                        aspects.add(
                            AspectarianEntry(
                                planet1 = p1.planet,
                                planet2 = p2.planet,
                                aspect = aspect,
                                orb = abs(shortestDiff - aspect.angle),
                            ),
                        )
                    }
                }
            }
        }
        return aspects
    }

    private fun detectStelliums(placements: List<ChartPlacement>): List<Sign> {
        val counts = placements.groupingBy { it.sign }.eachCount()
        return counts.filter { it.value >= 3 }.keys.toList()
    }

    private fun computeDominantElement(placements: List<ChartPlacement>): Element {
        val counts = placements.groupingBy { it.sign.element }.eachCount()
        return counts.maxByOrNull { it.value }?.key ?: Element.FIRE
    }

    private fun computeDominantModality(placements: List<ChartPlacement>): Modality {
        val counts = placements.groupingBy { it.sign.modality }.eachCount()
        return counts.maxByOrNull { it.value }?.key ?: Modality.CARDINAL
    }

    private fun calculateTransits(
        dateEpochMs: Long,
        natalChart: NatalChart,
        currentPlacements: List<ChartPlacement>,
        currentLat: Double,
        currentLng: Double,
        useCurrentLocation: Boolean,
    ): List<Transit> {
        // Full UTC JD including time-of-day (natal path already uses dayFraction)
        val julianDay = julianDayFromEpochMs(dateEpochMs)

        val currentAscendant = if (useCurrentLocation) {
            computeAscendant(julianDay, currentLat, currentLng)
        } else {
            null
        }

        val transits = mutableListOf<Transit>()
        for (current in currentPlacements) {
            for (natal in natalChart.placements) {
                if (current.planet == natal.planet) continue
                val diff = abs(current.degree - natal.degree)
                val shortestDiff = min(diff, 360.0 - diff)
                for (aspect in Aspect.entries) {
                    val orb = abs(shortestDiff - aspect.angle)
                    if (orb <= aspect.orb) {
                        var angularBoost = 1.0
                        if (currentAscendant != null) {
                            val house = houseFromLongitude(current.degree, currentAscendant)
                            if (house in listOf(House.FIRST, House.TENTH, House.SEVENTH, House.FOURTH)) {
                                angularBoost = 1.3
                            }
                        }
                        transits.add(
                            Transit(
                                planet = current.planet,
                                natalPlanet = natal.planet,
                                aspectType = aspect,
                                orb = orb,
                                isApplying = diff < aspect.angle,
                                angularBoost = angularBoost,
                            ),
                        )
                    }
                }
            }
        }
        return transits.sortedByDescending { it.strength }
    }

    /** Julian day (UTC) with fractional day from epoch ms — used for live sky + natal. */
    internal fun julianDayFromEpochMs(epochMs: Long): Double {
        val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { timeInMillis = epochMs }
        val y = cal.get(Calendar.YEAR)
        val m = cal.get(Calendar.MONTH) + 1
        val d = cal.get(Calendar.DAY_OF_MONTH)
        val h = cal.get(Calendar.HOUR_OF_DAY).toDouble()
        val min = cal.get(Calendar.MINUTE).toDouble()
        val s = cal.get(Calendar.SECOND).toDouble() + cal.get(Calendar.MILLISECOND) / 1000.0
        val dayFraction = (h + min / 60.0 + s / 3600.0) / 24.0
        return julianDayFor(y, m, d) + dayFraction
    }

    private fun simplifiedCurrentPlacements(
        dateEpochMs: Long,
        lat: Double,
        lng: Double,
    ): List<ChartPlacement> {
        val julianDay = julianDayFromEpochMs(dateEpochMs)
        val currentAscendant = if (lat != 0.0 || lng != 0.0) {
            computeAscendant(julianDay, lat, lng)
        } else {
            null
        }

        val planets = listOf(
            Planet.MOON, Planet.VENUS, Planet.MARS, Planet.JUPITER, Planet.SATURN,
            Planet.URANUS, Planet.NEPTUNE, Planet.PLUTO, Planet.CHIRON, Planet.NORTH_NODE,
        )
        return planets.map { planet ->
            val placement = simplifiedPlanetaryPosition(planet, julianDay, lat, lng)
            if (currentAscendant != null) {
                placement.copy(house = houseFromLongitude(placement.degree, currentAscendant))
            } else {
                placement
            }
        }
    }

    private fun positiveMod(a: Double, b: Double): Double {
        val result = a % b
        return if (result < 0) result + b else result
    }
}
