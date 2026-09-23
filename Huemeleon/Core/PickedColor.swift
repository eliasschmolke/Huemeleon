//
//  PickedColor.swift
//  Huemeleon
//
//  Farbmodell – exportunabhängig. Speichert sRGB-Komponenten und leitet
//  HEX / RGB255 / HSL daraus ab.
//

import SwiftUI
import AppKit

struct PickedColor: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    /// sRGB, jeweils 0…1
    var red: Double
    var green: Double
    var blue: Double
    /// Für spätere Wide-Gamut-Erweiterung offengehalten.
    var colorSpaceName: String = "sRGB"
    var timestamp: Date = Date()

    // MARK: Abgeleitete Werte

    var rgb255: (r: Int, g: Int, b: Int) {
        (Int((red * 255).rounded()),
         Int((green * 255).rounded()),
         Int((blue * 255).rounded()))
    }

    /// #RRGGBB (Großbuchstaben)
    var hex: String {
        let c = rgb255
        return String(format: "#%02X%02X%02X", c.r, c.g, c.b)
    }

    var hsl: (h: Int, s: Int, l: Int) {
        let v = ColorMath.rgbToHSL(r: red, g: green, b: blue)
        return (Int(v.h.rounded()), Int((v.s * 100).rounded()), Int((v.l * 100).rounded()))
    }

    var hsv: (h: Int, s: Int, v: Int) {
        let x = ColorMath.rgbToHSV(r: red, g: green, b: blue)
        return (Int(x.h.rounded()), Int((x.s * 100).rounded()), Int((x.v * 100).rounded()))
    }

    /// Rohe HSV-Werte (h 0…360, s/v 0…1) – für das Color Wheel.
    var hsvRaw: (h: Double, s: Double, v: Double) {
        ColorMath.rgbToHSV(r: red, g: green, b: blue)
    }

    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue)
    }
}

extension PickedColor {
    /// CMYK in Prozent (Druck-Näherung).
    var cmyk: (c: Int, m: Int, y: Int, k: Int) {
        let x = ColorMath.rgbToCMYK(r: red, g: green, b: blue)
        return (Int((x.c * 100).rounded()), Int((x.m * 100).rounded()),
                Int((x.y * 100).rounded()), Int((x.k * 100).rounded()))
    }

    /// Aus HSV (h 0…360, s/v 0…1). In einer Extension, damit der memberwise-Init erhalten bleibt.
    init(hue: Double, saturation: Double, value: Double) {
        let rgb = ColorMath.hsvToRGB(h: hue, s: saturation, v: value)
        self.init(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    /// Erzeugt aus einem HEX-String (#RRGGBB oder RRGGBB).
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let v = Int(h, radix: 16) else { return nil }
        self.init(red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255)
    }

    /// Erzeugt aus einem NSColor (wird vorher nach sRGB konvertiert).
    init?(nsColor: NSColor) {
        guard let c = nsColor.usingColorSpace(.sRGB) else { return nil }
        self.init(red: Double(c.redComponent),
                  green: Double(c.greenComponent),
                  blue: Double(c.blueComponent))
    }
}
