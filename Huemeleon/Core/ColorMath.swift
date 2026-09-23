//
//  ColorMath.swift
//  Huemeleon
//
//  Reine Farb-Utility-Funktionen (testbar).
//

import Foundation

enum ColorMath {
    /// sRGB (0…1) -> HSL: h in Grad (0…360), s/l in 0…1.
    static func rgbToHSL(r: Double, g: Double, b: Double) -> (h: Double, s: Double, l: Double) {
        let maxV = max(r, g, b)
        let minV = min(r, g, b)
        let delta = maxV - minV
        let l = (maxV + minV) / 2

        guard delta != 0 else { return (0, 0, l) }

        let s = l > 0.5 ? delta / (2 - maxV - minV) : delta / (maxV + minV)

        var h: Double
        switch maxV {
        case r: h = (g - b) / delta + (g < b ? 6 : 0)
        case g: h = (b - r) / delta + 2
        default: h = (r - g) / delta + 4
        }
        h *= 60
        return (h, s, l)
    }
}

extension ColorMath {
    /// sRGB (0…1) -> HSV: h in Grad (0…360), s/v in 0…1.
    static func rgbToHSV(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let maxV = max(r, g, b), minV = min(r, g, b), d = maxV - minV
        let v = maxV
        let s = maxV == 0 ? 0 : d / maxV
        var h = 0.0
        if d != 0 {
            switch maxV {
            case r: h = (g - b) / d + (g < b ? 6 : 0)
            case g: h = (b - r) / d + 2
            default: h = (r - g) / d + 4
            }
            h *= 60
        }
        return (h, s, v)
    }

    /// HSV (h in Grad, s/v 0…1) -> sRGB (0…1).
    static func hsvToRGB(h: Double, s: Double, v: Double) -> (r: Double, g: Double, b: Double) {
        if s <= 0 { return (v, v, v) }
        var hh = h.truncatingRemainder(dividingBy: 360)
        if hh < 0 { hh += 360 }
        hh /= 60
        let i = Int(floor(hh)), f = hh - Double(i)
        let p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f))
        switch i % 6 {
        case 0: return (v, t, p)
        case 1: return (q, v, p)
        case 2: return (p, v, t)
        case 3: return (p, q, v)
        case 4: return (t, p, v)
        default: return (v, p, q)
        }
    }
}

extension ColorMath {
    /// sRGB (0…1) -> CMYK (jeweils 0…1). Einfache Umrechnung ohne ICC-Profil,
    /// als Druck-Näherung gedacht (kein echtes Color-Management in V1).
    static func rgbToCMYK(r: Double, g: Double, b: Double) -> (c: Double, m: Double, y: Double, k: Double) {
        let k = 1 - max(r, g, b)
        if k >= 1 { return (0, 0, 0, 1) }
        let denom = 1 - k
        return ((1 - r - k) / denom, (1 - g - k) / denom, (1 - b - k) / denom, k)
    }
}
