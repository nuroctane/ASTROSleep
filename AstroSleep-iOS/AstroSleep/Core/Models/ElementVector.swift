import Foundation

// MARK: - Element Vector
/// [Fire, Earth, Air, Water] scoring vector with decimal precision
struct ElementVector: Codable, Equatable, AdditiveArithmetic {
    var fire: Double
    var earth: Double
    var air: Double
    var water: Double
    
    static let zero = ElementVector(fire: 0.0, earth: 0.0, air: 0.0, water: 0.0)
    static let ZERO = zero
    
    init(fire: Double = 0.0, earth: Double = 0.0, air: Double = 0.0, water: Double = 0.0) {
        self.fire = fire
        self.earth = earth
        self.air = air
        self.water = water
    }
    
    subscript(element: Element) -> Double {
        get {
            switch element {
            case .fire: return fire
            case .earth: return earth
            case .air: return air
            case .water: return water
            }
        }
        set {
            switch element {
            case .fire: fire = newValue
            case .earth: earth = newValue
            case .air: air = newValue
            case .water: water = newValue
            }
        }
    }
    
    subscript(index: Int) -> Double {
        get {
            switch index {
            case 0: return fire
            case 1: return earth
            case 2: return air
            case 3: return water
            default: return 0.0
            }
        }
        set {
            switch index {
            case 0: fire = newValue
            case 1: earth = newValue
            case 2: air = newValue
            case 3: water = newValue
            default: break
            }
        }
    }
    
    func dominant() -> Element {
        let values = [fire, earth, air, water]
        let maxValue = values.max() ?? 0.0
        if fire == maxValue { return .fire }
        if earth == maxValue { return .earth }
        if air == maxValue { return .air }
        return .water
    }
    
    func normalize(to target: Double = 10.0) -> ElementVector {
        let maxVal = max(fire, earth, air, water)
        guard maxVal > 0 else { return self }
        let scale = target / maxVal
        return ElementVector(
            fire: (fire * scale).roundedTo(2),
            earth: (earth * scale).roundedTo(2),
            air: (air * scale).roundedTo(2),
            water: (water * scale).roundedTo(2)
        )
    }
    
    func dotProduct(with other: ElementVector) -> Double {
        (fire * other.fire + earth * other.earth + air * other.air + water * other.water) / 4.0
    }
    
    func roundedTo(_ decimals: Int) -> ElementVector {
        ElementVector(
            fire: fire.roundedTo(decimals),
            earth: earth.roundedTo(decimals),
            air: air.roundedTo(decimals),
            water: water.roundedTo(decimals)
        )
    }
    
    // MARK: - AdditiveArithmetic
    static func + (lhs: ElementVector, rhs: ElementVector) -> ElementVector {
        ElementVector(
            fire: lhs.fire + rhs.fire,
            earth: lhs.earth + rhs.earth,
            air: lhs.air + rhs.air,
            water: lhs.water + rhs.water
        )
    }
    
    static func - (lhs: ElementVector, rhs: ElementVector) -> ElementVector {
        ElementVector(
            fire: lhs.fire - rhs.fire,
            earth: lhs.earth - rhs.earth,
            air: lhs.air - rhs.air,
            water: lhs.water - rhs.water
        )
    }
    
    static func += (lhs: inout ElementVector, rhs: ElementVector) {
        lhs = lhs + rhs
    }
    
    static func -= (lhs: inout ElementVector, rhs: ElementVector) {
        lhs = lhs - rhs
    }
    
    static func * (lhs: ElementVector, rhs: Double) -> ElementVector {
        ElementVector(
            fire: lhs.fire * rhs,
            earth: lhs.earth * rhs,
            air: lhs.air * rhs,
            water: lhs.water * rhs
        )
    }
    
    static func / (lhs: ElementVector, rhs: Double) -> ElementVector {
        guard rhs != 0 else { return lhs }
        return ElementVector(
            fire: lhs.fire / rhs,
            earth: lhs.earth / rhs,
            air: lhs.air / rhs,
            water: lhs.water / rhs
        )
    }
}

// MARK: - Double Extension

extension Double {
    func roundedTo(_ decimals: Int) -> Double {
        let multiplier = pow(10.0, Double(decimals))
        return (self * multiplier).rounded() / multiplier
    }
}

// MARK: - Element Vector Presets

extension ElementVector {
    /// Element vectors for each sign (archetypal signatures)
    static func forSign(_ sign: Sign) -> ElementVector {
        switch sign {
        case .aries:     return ElementVector(fire: 4.0, earth: 0.0, air: 1.0, water: 0.0)
        case .taurus:    return ElementVector(fire: 0.0, earth: 4.0, air: 0.0, water: 1.0)
        case .gemini:    return ElementVector(fire: 1.0, earth: 0.0, air: 4.0, water: 0.0)
        case .cancer:    return ElementVector(fire: 0.0, earth: 1.0, air: 0.0, water: 4.0)
        case .leo:       return ElementVector(fire: 4.0, earth: 0.0, air: 1.0, water: 0.0)
        case .virgo:     return ElementVector(fire: 0.0, earth: 4.0, air: 0.0, water: 1.0)
        case .libra:     return ElementVector(fire: 1.0, earth: 0.0, air: 4.0, water: 0.0)
        case .scorpio:   return ElementVector(fire: 0.0, earth: 1.0, air: 0.0, water: 4.0)
        case .ophiuchus: return ElementVector(fire: 1.0, earth: 1.0, air: 2.0, water: 5.0)
        case .sagittarius: return ElementVector(fire: 4.0, earth: 0.0, air: 1.0, water: 0.0)
        case .capricorn: return ElementVector(fire: 0.0, earth: 4.0, air: 0.0, water: 1.0)
        case .aquarius:  return ElementVector(fire: 1.0, earth: 0.0, air: 4.0, water: 0.0)
        case .pisces:    return ElementVector(fire: 0.0, earth: 1.0, air: 0.0, water: 4.0)
        }
    }
    
    /// House elemental biases (Equal house system)
    static func forHouse(_ house: House) -> ElementVector {
        switch house {
        case .first:   return ElementVector(fire: 3.0, earth: 0.0, air: 1.0, water: 0.0)
        case .second:  return ElementVector(fire: 0.0, earth: 4.0, air: 0.0, water: 1.0)
        case .third:   return ElementVector(fire: 1.0, earth: 0.0, air: 4.0, water: 0.0)
        case .fourth:  return ElementVector(fire: 0.0, earth: 1.0, air: 0.0, water: 4.0)
        case .fifth:   return ElementVector(fire: 4.0, earth: 0.0, air: 1.0, water: 0.0)
        case .sixth:   return ElementVector(fire: 0.0, earth: 4.0, air: 0.0, water: 1.0)
        case .seventh: return ElementVector(fire: 1.0, earth: 0.0, air: 4.0, water: 0.0)
        case .eighth:  return ElementVector(fire: 0.0, earth: 1.0, air: 0.0, water: 4.0)
        case .ninth:   return ElementVector(fire: 4.0, earth: 0.0, air: 1.0, water: 0.0)
        case .tenth:   return ElementVector(fire: 0.0, earth: 4.0, air: 0.0, water: 1.0)
        case .eleventh: return ElementVector(fire: 1.0, earth: 0.0, air: 4.0, water: 0.0)
        case .twelfth:  return ElementVector(fire: 0.0, earth: 1.0, air: 0.0, water: 4.0)
        }
    }
    
    /// Phase deltas for nightly transit scoring
    static func phaseDelta(_ phase: MoonPhase) -> ElementVector {
        switch phase {
        case .newMoon:         return ElementVector(fire: 1.0, earth: 0.0, air: 0.0, water: 2.0)
        case .waxingCrescent:  return ElementVector(fire: 1.0, earth: 0.0, air: 1.0, water: 1.0)
        case .firstQuarter:    return ElementVector(fire: 2.0, earth: 0.0, air: 1.0, water: 0.0)
        case .waxingGibbous:   return ElementVector(fire: 1.0, earth: 1.0, air: 0.0, water: 1.0)
        case .fullMoon:        return ElementVector(fire: 0.0, earth: 0.0, air: 2.0, water: 2.0)
        case .waningGibbous:   return ElementVector(fire: 0.0, earth: 1.0, air: 1.0, water: 1.0)
        case .lastQuarter:     return ElementVector(fire: 0.0, earth: 2.0, air: 0.0, water: 1.0)
        case .waningCrescent:  return ElementVector(fire: 0.0, earth: 1.0, air: 0.0, water: 3.0)
        }
    }
    
    /// Transit deltas for a planet/aspect combination
    static func transitDelta(planet: Planet, aspect: Aspect) -> ElementVector? {
        let deltas: [Planet: [Aspect: ElementVector]] = [
            .moon: [
                .conjunction: ElementVector(fire: 0.0, earth: 0.0, air: 0.0, water: 3.0),
                .trine: ElementVector(fire: 0.0, earth: 0.0, air: 1.0, water: 2.0),
                .square: ElementVector(fire: 2.0, earth: 0.0, air: 0.0, water: 1.0),
                .sextile: ElementVector(fire: 0.0, earth: 0.0, air: 1.0, water: 1.5)
            ],
            .venus: [
                .conjunction: ElementVector(fire: 0.0, earth: 1.0, air: 1.0, water: 2.0),
                .trine: ElementVector(fire: 0.0, earth: 1.0, air: 0.0, water: 1.0),
                .sextile: ElementVector(fire: 0.5, earth: 0.5, air: 0.5, water: 1.0)
            ],
            .mars: [
                .conjunction: ElementVector(fire: 3.0, earth: 0.0, air: 1.0, water: 0.0),
                .square: ElementVector(fire: 3.0, earth: 0.0, air: 0.0, water: -1.0),
                .trine: ElementVector(fire: 2.0, earth: 0.0, air: 0.5, water: 0.0)
            ],
            .jupiter: [
                .conjunction: ElementVector(fire: 2.0, earth: 1.0, air: 1.0, water: 1.0),
                .trine: ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
                .sextile: ElementVector(fire: 1.5, earth: 0.5, air: 1.0, water: 0.5)
            ],
            .saturn: [
                .conjunction: ElementVector(fire: 0.0, earth: 3.0, air: 0.0, water: 0.0),
                .trine: ElementVector(fire: 0.0, earth: 2.0, air: 0.0, water: 0.0),
                .square: ElementVector(fire: -1.0, earth: 2.0, air: 0.0, water: 0.0)
            ],
            .uranus: [
                .conjunction: ElementVector(fire: 1.0, earth: 0.0, air: 3.0, water: 0.0),
                .trine: ElementVector(fire: 0.5, earth: 0.0, air: 2.0, water: 0.0)
            ],
            .neptune: [
                .conjunction: ElementVector(fire: 0.0, earth: 0.0, air: 1.0, water: 3.0),
                .trine: ElementVector(fire: 0.0, earth: 0.0, air: 1.0, water: 2.0),
                .sextile: ElementVector(fire: 0.0, earth: 0.0, air: 0.5, water: 1.5)
            ],
            .pluto: [
                .conjunction: ElementVector(fire: 0.0, earth: 0.0, air: 0.0, water: 4.0),
                .trine: ElementVector(fire: 0.0, earth: 0.0, air: 0.0, water: 2.5),
                .square: ElementVector(fire: 0.0, earth: 0.0, air: 0.0, water: 2.0)
            ],
            .chiron: [
                .conjunction: ElementVector(fire: 0.5, earth: 0.0, air: 1.0, water: 2.0),
                .trine: ElementVector(fire: 0.0, earth: 0.0, air: 0.5, water: 1.5)
            ],
            .lilith: [
                .conjunction: ElementVector(fire: 0.0, earth: 0.0, air: 0.0, water: 1.5),
                .square: ElementVector(fire: 0.0, earth: 0.0, air: 0.0, water: 1.0)
            ],
            .northNode: [
                .conjunction: ElementVector(fire: 0.5, earth: 0.5, air: 0.5, water: 1.0)
            ]
        ]
        
        return deltas[planet]?[aspect]
    }
}
