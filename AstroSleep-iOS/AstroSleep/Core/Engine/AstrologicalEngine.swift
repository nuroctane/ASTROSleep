import Foundation

// MARK: - Astrological Engine
/// Computes natal charts, transit positions, and nightly scores.
/// All calculations follow the Sidereal 13-sign Sharatan ayanamsha standard.
final class AstrologicalEngine {
    static let shared = AstrologicalEngine()
    
    // Sharatan ayanamsha offset (approximate, exact via ephemeris)
    private let sharatanAyanamsha: Double = 24.0 + 6.0 / 60.0 + 18.0 / 3600.0 // 24°06'18"
    
    // Mean sidereal year in days
    private let siderealYear: Double = 365.256363004
    
    // Mean synodic month in days
    private let synodicMonth: Double = 29.53058867
    
    private init() {}
    
    // MARK: - Natal Chart Computation
    
    /// Computes a complete natal chart from birth data.
    /// This is a simplified astronomical model. For production, integrate Swiss Ephemeris.
    func computeNatalChart(
        birthDate: Date,
        birthTime: Date?,
        lat: Double,
        lng: Double
    ) -> NatalChart {
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents([.year, .month, .day], from: birthDate)
        // Merge birth time into fractional JD (was date-only — ignored hour/minute).
        var dayFraction = 0.5 // noon default when time unknown
        let hasBirthTime = birthTime != nil
        if let birthTime {
            let tc = calendar.dateComponents([.hour, .minute, .second], from: birthTime)
            let h = Double(tc.hour ?? 12)
            let m = Double(tc.minute ?? 0)
            let s = Double(tc.second ?? 0)
            dayFraction = (h + m / 60.0 + s / 3600.0) / 24.0
            components.hour = tc.hour
            components.minute = tc.minute
        }
        
        let julianDay = julianDayFor(
            year: components.year ?? 2000,
            month: components.month ?? 1,
            day: components.day ?? 1
        ) + dayFraction
        
        var placements = Planet.allCases.map { planet -> ChartPlacement in
            simplifiedPlanetaryPosition(
                planet: planet,
                julianDay: julianDay,
                lat: lat,
                lng: lng
            )
        }
        
        let ascendant = hasBirthTime ? computeAscendant(julianDay: julianDay, lat: lat, lng: lng) : nil
        // Assign equal houses from ascendant when birth time known
        if let asc = ascendant {
            placements = placements.map { p in
                let house = houseFromLongitude(p.degree, ascendant: asc)
                return ChartPlacement(
                    planet: p.planet,
                    sign: p.sign,
                    house: house,
                    degree: p.degree,
                    isRetrograde: p.isRetrograde
                )
            }
        }
        
        let aspects = computeAspects(placements: placements)
        let stelliums = detectStelliums(placements: placements)
        
        return NatalChart(
            computedAt: Date(),
            placements: placements,
            ascendant: ascendant,
            mc: nil,
            dominantElement: computeDominantElement(placements: placements),
            dominantModality: computeDominantModality(placements: placements),
            aspects: aspects,
            stelliums: stelliums,
            hasBirthTime: hasBirthTime
        )
    }
    
    // MARK: - Base Score Derivation
    
    func deriveBaseScore(from chart: NatalChart) -> ElementVector {
        var score = ElementVector.zero
        
        // Moon sign — weight 4.0 (strongest influence on sleep)
        if let moonSign = chart.moonSign {
            score += ElementVector.forSign(moonSign) * 4.0
        }
        
        // Sun sign — weight 2.0
        if let sunSign = chart.sunSign {
            score += ElementVector.forSign(sunSign) * 2.0
        }
        
        // Ascendant — weight 1.5
        if let ascendant = chart.ascendant {
            score += ElementVector.forSign(ascendant) * 1.5
        }
        
        // Personal planets
        if let mercury = chart.mercurySign {
            score += ElementVector.forSign(mercury) * 1.0
        }
        if let venus = chart.venusSign {
            score += ElementVector.forSign(venus) * 1.5
        }
        if let mars = chart.marsSign {
            score += ElementVector.forSign(mars) * 1.0
        }
        
        // Social planets
        if let jupiter = chart.jupiterSign {
            score += ElementVector.forSign(jupiter) * 0.8
        }
        if let saturn = chart.saturnSign {
            score += ElementVector.forSign(saturn) * 0.7
        }
        
        // Transpersonal planets
        if let uranus = chart.uranusSign {
            score += ElementVector.forSign(uranus) * 0.5
        }
        if let neptune = chart.neptuneSign {
            score += ElementVector.forSign(neptune) * 0.8
        }
        if let pluto = chart.plutoSign {
            score += ElementVector.forSign(pluto) * 0.6
        }
        
        // Asteroids
        if let chiron = chart.chironSign {
            score += ElementVector.forSign(chiron) * 0.5
        }
        if let lilith = chart.lilithSign {
            score += ElementVector.forSign(lilith) * 0.4
        }
        
        // Lunar nodes
        if let northNode = chart.northNode {
            score[northNode.sign.element] += 0.6
        }
        if let southNode = chart.southNode {
            score[southNode.sign.element] += 0.4
        }
        
        // Dominant element bonus
        let dominantElement = score.dominant()
        score[dominantElement] += 2.0
        
        // Modality modifier
        switch chart.dominantModality {
        case .fixed:
            score[.earth] += 1.0
        case .cardinal:
            score[.fire] += 1.0
        case .mutable:
            score[.air] += 1.0
        }
        
        // Stellium bonus (3+ planets in same sign)
        for stellium in chart.stelliums {
            score += ElementVector.forSign(stellium) * 1.2
        }
        
        // House placements (if birth time known)
        if chart.hasBirthTime {
            if let moonHouse = chart.moonHouse {
                score += ElementVector.forHouse(moonHouse) * 1.0
            }
            if let sunHouse = chart.sunHouse {
                score += ElementVector.forHouse(sunHouse) * 0.5
            }
            // House rulers
            for house in House.allCases {
                let ruler = chart.houseRuler(house)
                if let rulerSign = chart.placement(for: ruler)?.sign {
                    score += ElementVector.forSign(rulerSign) * 0.3
                }
            }
        }
        
        return score.normalize(to: 10.0)
    }
    
    // MARK: - Nightly Transit Scoring
    
    func calculateNightlyScore(
        baseScore: ElementVector,
        date: Date,
        natalChart: NatalChart,
        currentLat: Double = 0,
        currentLng: Double = 0,
        useCurrentLocation: Bool = false
    ) -> NightlyScoreResult {
        var score = baseScore
        
        let moonPhase = calculateMoonPhase(date: date)
        score += ElementVector.phaseDelta(moonPhase)
        
        // Callers pass resolved coordinates (birth or GPS). Prefer non-zero provided values.
        let transitLat = currentLat
        let transitLng = currentLng
        
        // Compute current placements once and reuse
        let currentPlacements = simplifiedCurrentPlacements(
            date: date,
            lat: transitLat,
            lng: transitLng
        )
        
        let transits = calculateTransits(
            date: date,
            natalChart: natalChart,
            currentPlacements: currentPlacements,
            currentLat: transitLat,
            currentLng: transitLng,
            useCurrentLocation: useCurrentLocation
        )
        for transit in transits {
            if let delta = ElementVector.transitDelta(planet: transit.planet, aspect: transit.aspectType) {
                let orbFactor = max(0, 1.0 - (transit.orb / transit.aspectType.orb))
                score += delta * orbFactor
            }
        }
        
        // Current house emphasis (if birth time known)
        if natalChart.hasBirthTime {
            for placement in currentPlacements {
                if let house = placement.house {
                    let planetWeight = placement.planet.baseScoreWeight
                    score += ElementVector.forHouse(house) * 0.5 * planetWeight
                }
            }
        }
        
        // Current stelliums
        let currentStelliumSigns = detectStelliums(in: currentPlacements)
        var stelliumList: [Stellium] = []
        for sign in currentStelliumSigns {
            let planets = currentPlacements.filter { $0.sign == sign }.map { $0.planet }
            stelliumList.append(Stellium(sign: sign, planets: planets))
            score += ElementVector.forSign(sign) * 0.8
        }
        
        return NightlyScoreResult(
            elementScore: score.normalize(to: 10.0),
            moonPhase: moonPhase,
            activeTransits: transits,
            dominantElement: score.dominant(),
            topTransit: transits.max { $0.strength < $1.strength },
            stelliums: stelliumList
        )
    }
    
    // MARK: - Moon Phase Calculation
    
    func calculateMoonPhase(date: Date) -> MoonPhase {
        // Known new moon: 2000-01-06 18:14 UTC ≈ 947182440
        let knownNewMoon = Date(timeIntervalSince1970: 947_182_440)
        let secondsSinceNewMoon = date.timeIntervalSince(knownNewMoon)
        let daysSinceNewMoon = secondsSinceNewMoon / 86400.0
        var rem = daysSinceNewMoon.truncatingRemainder(dividingBy: synodicMonth)
        if rem < 0 { rem += synodicMonth }
        let phaseCycle = rem / synodicMonth
        
        switch phaseCycle {
        case 0.0..<0.03, 0.97...1.0:
            return .newMoon
        case 0.03..<0.22:
            return .waxingCrescent
        case 0.22..<0.28:
            return .firstQuarter
        case 0.28..<0.47:
            return .waxingGibbous
        case 0.47..<0.53:
            return .fullMoon
        case 0.53..<0.72:
            return .waningGibbous
        case 0.72..<0.78:
            return .lastQuarter
        default:
            return .waningCrescent
        }
    }
    
    // MARK: - Private Helpers
    
    private func julianDayFor(year: Int, month: Int, day: Int) -> Double {
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        let jd = Double(day) + Double((153 * m + 2) / 5) + 365 * Double(y) + Double(y / 4) - Double(y / 100) + Double(y / 400) - 32045
        return jd
    }
    
    private func simplifiedPlanetaryPosition(planet: Planet, julianDay: Double, lat: Double, lng: Double) -> ChartPlacement {
        // Simplified orbital calculations
        // In production, replace with actual ephemeris computation
        let daysSinceEpoch = julianDay - 2451545.0
        
        var longitude: Double
        var isRetrograde = false
        
        switch planet {
        case .sun:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 365.25, 360.0)
        case .moon:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 27.32, 360.0)
        case .mercury:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 87.97, 360.0)
            isRetrograde = positiveMod(daysSinceEpoch, 116.0) < 21.0
        case .venus:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 224.7, 360.0)
            isRetrograde = positiveMod(daysSinceEpoch, 584.0) < 42.0
        case .mars:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 686.98, 360.0)
            isRetrograde = positiveMod(daysSinceEpoch, 780.0) < 72.0
        case .jupiter:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 4332.59, 360.0)
        case .saturn:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 10759.22, 360.0)
        case .uranus:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 30685.4, 360.0)
        case .neptune:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 60189.0, 360.0)
        case .pluto:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 90560.0, 360.0)
        case .chiron:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 5068.0, 360.0)
        case .lilith:
            longitude = positiveMod(daysSinceEpoch * 360.0 / 6798.0, 360.0)
        case .northNode:
            longitude = positiveMod(125.0 - daysSinceEpoch * 360.0 / 6793.0, 360.0)
        case .southNode:
            let northNodeLongitude = positiveMod(125.0 - daysSinceEpoch * 360.0 / 6793.0, 360.0)
            longitude = positiveMod(northNodeLongitude + 180.0, 360.0)
        }
        
        // Apply ayanamsha for sidereal
        let siderealLongitude = positiveMod(longitude - sharatanAyanamsha + 360.0, 360.0)
        
        let sign = signFromLongitude(siderealLongitude)
        let house = houseFromLongitude(siderealLongitude, ascendant: nil) // Simplified
        
        return ChartPlacement(
            planet: planet,
            sign: sign,
            house: house,
            degree: siderealLongitude,
            isRetrograde: isRetrograde
        )
    }
    
    private func computeAscendant(julianDay: Double, lat: Double, lng: Double) -> Sign {
        let lst = localSiderealTime(julianDay: julianDay, longitude: lng)
        let ascLongitude = positiveMod(lst - 90.0 + 360.0, 360.0)
        return signFromLongitude(ascLongitude)
    }
    
    private func localSiderealTime(julianDay: Double, longitude: Double) -> Double {
        let jd2000 = julianDay - 2451545.0
        let gmst = 280.46061837 + 360.98564736629 * jd2000
        return positiveMod(gmst + longitude + 360.0, 360.0)
    }
    
    /// Equal 13-sign sidereal sectors (360°/13). Pisces is reachable; Ophiuchus is a real sector.
    private func signFromLongitude(_ longitude: Double) -> Sign {
        let signs = Sign.allCases
        let sector = 360.0 / Double(signs.count) // ≈ 27.6923°
        let lon = positiveMod(longitude, 360.0)
        let index = min(Int(lon / sector), signs.count - 1)
        return signs[index]
    }
    
    private func houseFromLongitude(_ longitude: Double, ascendant: Sign?) -> House? {
        guard let asc = ascendant else { return nil }
        let sector = 360.0 / 13.0
        let ascDegree = Double(asc.index) * sector
        let relativeDegree = positiveMod(longitude - ascDegree + 360.0, 360.0)
        let houseNumber = Int(relativeDegree / 30.0) + 1 // 12 houses remain 30° equal house
        return House(rawValue: min(max(houseNumber, 1), 12))
    }
    
    private func computeAspects(placements: [ChartPlacement]) -> [AspectarianEntry] {
        var aspects: [AspectarianEntry] = []
        
        for i in 0..<placements.count {
            for j in (i + 1)..<placements.count {
                let p1 = placements[i]
                let p2 = placements[j]
                
                let diff = abs(p1.degree - p2.degree)
                let shortestDiff = min(diff, 360.0 - diff)
                
                for aspect in Aspect.allCases {
                    if abs(shortestDiff - aspect.angle) <= aspect.orb {
                        aspects.append(AspectarianEntry(
                            planet1: p1.planet,
                            planet2: p2.planet,
                            aspect: aspect,
                            orb: abs(shortestDiff - aspect.angle)
                        ))
                    }
                }
            }
        }
        
        return aspects
    }
    
    private func detectStelliums(placements: [ChartPlacement]) -> [Sign] {
        var signCounts: [Sign: Int] = [:]
        for placement in placements {
            signCounts[placement.sign, default: 0] += 1
        }
        return signCounts.filter { $0.value >= 3 }.map { $0.key }
    }
    
    private func detectStelliums(in placements: [ChartPlacement]) -> [Sign] {
        detectStelliums(placements: placements)
    }
    
    private func computeDominantElement(placements: [ChartPlacement]) -> Element {
        var counts: [Element: Int] = [:]
        for placement in placements {
            counts[placement.sign.element, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key ?? .fire
    }
    
    private func computeDominantModality(placements: [ChartPlacement]) -> Modality {
        var counts: [Modality: Int] = [:]
        for placement in placements {
            counts[placement.sign.modality, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key ?? .cardinal
    }
    
    private func calculateTransits(
        date: Date,
        natalChart: NatalChart,
        currentPlacements: [ChartPlacement],
        currentLat: Double = 0,
        currentLng: Double = 0,
        useCurrentLocation: Bool = false
    ) -> [Transit] {
        let julianDay = julianDayFor(
            year: Calendar.current.component(.year, from: date),
            month: Calendar.current.component(.month, from: date),
            day: Calendar.current.component(.day, from: date)
        )
        
        var transits: [Transit] = []
        
        // Compute current ascendant for angular emphasis if location available
        var currentAscendant: Sign?
        if useCurrentLocation {
            currentAscendant = computeAscendant(julianDay: julianDay, lat: currentLat, lng: currentLng)
        }
        
        for current in currentPlacements {
            for natal in natalChart.placements {
                if current.planet == natal.planet { continue }
                
                let diff = abs(current.degree - natal.degree)
                let shortestDiff = min(diff, 360.0 - diff)
                
                for aspect in Aspect.allCases {
                    let orb = abs(shortestDiff - aspect.angle)
                    if orb <= aspect.orb {
                        
                        // Angular emphasis: boost transits where current planet is angular
                        // (near Ascendant, MC, Descendant, or IC at current location)
                        var angularBoost = 1.0
                        if let asc = currentAscendant {
                            let currentHouse = houseFromLongitude(current.degree, ascendant: asc)
                            if let house = currentHouse, [House.first, .tenth, .seventh, .fourth].contains(house) {
                                angularBoost = 1.3
                            }
                        }
                        
                        transits.append(Transit(
                            planet: current.planet,
                            natalPlanet: natal.planet,
                            aspectType: aspect,
                            orb: orb,
                            isApplying: diff < aspect.angle,
                            angularBoost: angularBoost
                        ))
                    }
                }
            }
        }
        
        return transits.sorted { $0.strength > $1.strength }
    }
    
    private func simplifiedCurrentPlacements(date: Date, lat: Double = 0, lng: Double = 0) -> [ChartPlacement] {
        let julianDay = julianDayFor(
            year: Calendar.current.component(.year, from: date),
            month: Calendar.current.component(.month, from: date),
            day: Calendar.current.component(.day, from: date)
        )
        
        // Compute current ascendant from provided location (birth or current)
        let currentAscendant = (lat != 0 || lng != 0)
            ? computeAscendant(julianDay: julianDay, lat: lat, lng: lng)
            : nil
        
        return [Planet.moon, Planet.venus, Planet.mars, Planet.jupiter, Planet.saturn, Planet.uranus, Planet.neptune, Planet.pluto, Planet.chiron, Planet.northNode].map { planet in
            var placement = simplifiedPlanetaryPosition(planet: planet, julianDay: julianDay, lat: lat, lng: lng)
            // Recompute house using current ascendant if location is available
            if let asc = currentAscendant {
                let house = houseFromLongitude(placement.degree, ascendant: asc)
                placement = ChartPlacement(
                    planet: placement.planet,
                    sign: placement.sign,
                    house: house,
                    degree: placement.degree,
                    isRetrograde: placement.isRetrograde
                )
            }
            return placement
        }
    }
    
    private func positiveMod(_ a: Double, _ b: Double) -> Double {
        let result = a.truncatingRemainder(dividingBy: b)
        return result < 0 ? result + b : result
    }
}
