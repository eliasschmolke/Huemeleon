//
//  AppIconTinter.swift
//  Huemeleon
//
//  Färbt das Dock-Icon live in die aktuell gepickte Farbe – und behält dabei die
//  Icon-Composer-Glas-Optik. Trick: das schwarze Glas-Chamäleon trägt die Optik als
//  Helligkeits-Verlauf (dunkler Körper, heller Glanz, mittelgrauer Rand). Eine
//  Gradient-Map bildet diese Luminanz auf drei Anker ab:
//    Schatten -> dunklere Variante der Farbe,  Mitteltöne -> volle Farbe,  Glanz -> Weiß.
//  Ergebnis wird auf die Squircle-Platte (logo-bg) komponiert und als App-Icon gesetzt.
//

import AppKit

@MainActor
final class AppIconTinter {
    static let shared = AppIconTinter()

    // Gradient-Map-Anker, auf den Luminanzbereich des Chamäleon-Assets abgestimmt.
    private let pivot: CGFloat = 0.16   // Körper-Helligkeit -> volle Farbe
    private let hi:    CGFloat = 0.70   // hellster Glanz     -> Weiß
    private let lo:    CGFloat = 0.10   // tiefster Schatten  -> dunkle Farbe

    private let finalSide = 1024        // Ausgabe-Icon (Retina-sicher)
    private let workHeight = 512        // Arbeitsauflösung des Chamäleons

    // >>> Hier justieren, falls dir Größe/Verhältnis nicht gefällt <<<
    /// Anteil der Platte an der Icon-Fläche. Kleiner = kleineres Dock-Icon.
    /// Apple-Standard-Icons haben rundum Rand und liegen bei ~0.80.
    private let iconFraction: CGFloat = 0.82
    /// Chamäleon-Größe relativ zur Platte. Größer = Chamäleon füllt die Platte mehr.
    private let chameleonScale: CGFloat = 0.74

    private var chameleonCG: CGImage?
    private var bgCG: CGImage?
    private let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

    private init() {}

    /// Baut ein getöntes Dock-Icon für die Farbe. nil, falls Assets fehlen.
    func icon(for color: PickedColor) -> NSImage? {
        guard let cham = loadChameleon(), let bg = loadBG() else { return nil }
        let tint = (r: CGFloat(color.red), g: CGFloat(color.green), b: CGFloat(color.blue))
        guard let tinted = tintedChameleon(cham, tint: tint) else { return nil }

        let side = finalSide
        guard let ctx = CGContext(data: nil, width: side, height: side,
                                  bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.interpolationQuality = .high

        // Platte mit Rand („Keyline") zeichnen, damit das Icon so groß wie die
        // Nachbar-Icons im Dock wirkt.
        let plate = CGFloat(side) * iconFraction
        let inset = (CGFloat(side) - plate) / 2
        ctx.draw(bg, in: CGRect(x: inset, y: inset, width: plate, height: plate))

        // Chamäleon relativ zur Platte, zentriert, Seitenverhältnis erhalten.
        let chH = plate * chameleonScale
        let aspect = CGFloat(tinted.width) / CGFloat(tinted.height)
        let chW = chH * aspect
        let cx = (CGFloat(side) - chW) / 2
        let cy = (CGFloat(side) - chH) / 2
        ctx.draw(tinted, in: CGRect(x: cx, y: cy, width: chW, height: chH))

        guard let composed = ctx.makeImage() else { return nil }
        return NSImage(cgImage: composed, size: NSSize(width: side, height: side))
    }

    // MARK: - Gradient-Map

    private func tintedChameleon(_ cg: CGImage, tint: (r: CGFloat, g: CGFloat, b: CGFloat)) -> CGImage? {
        let h = workHeight
        let w = max(1, Int((CGFloat(cg.width) / CGFloat(cg.height) * CGFloat(h)).rounded()))
        let bytesPerRow = w * 4
        var buf = [UInt8](repeating: 0, count: h * bytesPerRow)

        let made: CGImage? = buf.withUnsafeMutableBytes { raw -> CGImage? in
            guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: srgb,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return nil }
            ctx.interpolationQuality = .high
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

            let dark = (r: tint.r * 0.55, g: tint.g * 0.55, b: tint.b * 0.55)
            let ptr = raw.bindMemory(to: UInt8.self)
            var i = 0
            let count = w * h
            while i < count {
                let o = i * 4
                let a = CGFloat(ptr[o + 3]) / 255.0
                if a > 0 {
                    // premultipliziert -> Farbe zurückrechnen
                    let r = CGFloat(ptr[o])     / 255.0 / a
                    let g = CGFloat(ptr[o + 1]) / 255.0 / a
                    let b = CGFloat(ptr[o + 2]) / 255.0 / a
                    let l = 0.299 * r + 0.587 * g + 0.114 * b
                    var nr: CGFloat, ng: CGFloat, nb: CGFloat
                    if l >= pivot {
                        let up = pow(min(max((l - pivot) / (hi - pivot), 0), 1), 0.85)
                        nr = tint.r + (1 - tint.r) * up
                        ng = tint.g + (1 - tint.g) * up
                        nb = tint.b + (1 - tint.b) * up
                    } else {
                        let dn = min(max((pivot - l) / (pivot - lo), 0), 1)
                        nr = tint.r + (dark.r - tint.r) * dn
                        ng = tint.g + (dark.g - tint.g) * dn
                        nb = tint.b + (dark.b - tint.b) * dn
                    }
                    ptr[o]     = UInt8(min(max(nr, 0), 1) * a * 255 + 0.5)
                    ptr[o + 1] = UInt8(min(max(ng, 0), 1) * a * 255 + 0.5)
                    ptr[o + 2] = UInt8(min(max(nb, 0), 1) * a * 255 + 0.5)
                }
                i += 1
            }
            return ctx.makeImage()
        }
        return made
    }

    // MARK: - Assets

    private func loadChameleon() -> CGImage? {
        if let c = chameleonCG { return c }
        guard let img = NSImage(named: "glass-cameleon-logo"),
              let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        chameleonCG = cg
        return cg
    }

    private func loadBG() -> CGImage? {
        if let c = bgCG { return c }
        guard let img = NSImage(named: "logo-bg"),
              let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        bgCG = cg
        return cg
    }
}
