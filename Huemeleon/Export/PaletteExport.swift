//
//  PaletteExport.swift
//  Huemeleon
//
//  Reine Export-Funktionen: Palette -> Data pro Zielformat. Testbar, ohne UI.
//

import Foundation

enum PaletteExportFormat: String, CaseIterable, Identifiable {
    case ase, gpl, css, json, txt
    var id: String { rawValue }
    var fileExtension: String { rawValue }

    var displayName: String {
        switch self {
        case .ase:  return "Adobe Swatch Exchange (.ase)"
        case .gpl:  return "GIMP / Aseprite (.gpl)"
        case .css:  return "CSS (.css)"
        case .json: return "JSON (.json)"
        case .txt:  return "Text (.txt)"
        }
    }

    func data(for palette: Palette) -> Data {
        switch self {
        case .ase:  return PaletteExport.ase(palette)
        case .gpl:  return PaletteExport.gpl(palette)
        case .css:  return PaletteExport.css(palette)
        case .json: return PaletteExport.json(palette)
        case .txt:  return PaletteExport.txt(palette)
        }
    }
}

enum PaletteExport {

    // MARK: GIMP Palette (.gpl) – von Aseprite & GIMP nativ gelesen
    static func gpl(_ p: Palette) -> Data {
        var s = "GIMP Palette\n"
        s += "Name: \(p.name)\n"
        s += "Columns: 0\n#\n"
        for c in p.colors {
            let v = c.rgb255
            s += String(format: "%3d %3d %3d\t%@\n", v.r, v.g, v.b, c.hex)
        }
        return Data(s.utf8)
    }

    // MARK: Adobe Swatch Exchange (.ase) – binär, Big-Endian
    static func ase(_ p: Palette) -> Data {
        var d = Data()
        d.append(contentsOf: Array("ASEF".utf8))     // Signatur
        d.appendUInt16BE(1); d.appendUInt16BE(0)      // Version 1.0
        d.appendUInt32BE(UInt32(p.colors.count + 2))  // Group-Start + Farben + Group-End

        // Group-Start (0xC001) mit Palettenname – verhindert Adobe-Dublette
        var groupBody = Data()
        let gname = Array((p.name.isEmpty ? "Palette" : p.name).utf16)
        groupBody.appendUInt16BE(UInt16(gname.count + 1))
        for u in gname { groupBody.appendUInt16BE(u) }
        groupBody.appendUInt16BE(0)
        d.appendUInt16BE(0xC001)
        d.appendUInt32BE(UInt32(groupBody.count))
        d.append(groupBody)

        for c in p.colors {
            var body = Data()
            let name = Array(c.hex.utf16)
            body.appendUInt16BE(UInt16(name.count + 1))   // Länge inkl. Null-Terminator (UTF-16 Einheiten)
            for u in name { body.appendUInt16BE(u) }
            body.appendUInt16BE(0)                        // Null-Terminator
            body.append(contentsOf: Array("RGB ".utf8))   // Farbmodell (4 Byte)
            body.appendFloat32BE(Float(c.red))
            body.appendFloat32BE(Float(c.green))
            body.appendFloat32BE(Float(c.blue))
            body.appendUInt16BE(2)                        // Farbtyp: 2 = Normal/Process

            d.appendUInt16BE(0x0001)                      // Blocktyp: Farbeintrag
            d.appendUInt32BE(UInt32(body.count))          // Blocklänge
            d.append(body)
        }

        // Group-End (0xC002)
        d.appendUInt16BE(0xC002)
        d.appendUInt32BE(0)
        return d
    }

    // MARK: CSS (.css) – Custom Properties
    static func css(_ p: Palette) -> Data {
        let slug = slugify(p.name)
        var s = "/* \(p.name) */\n:root {\n"
        for (i, c) in p.colors.enumerated() {
            s += "  --\(slug)-\(i + 1): \(c.hex);\n"
        }
        s += "}\n"
        return Data(s.utf8)
    }

    // MARK: JSON (.json) – vollständiges internes Modell
    static func json(_ p: Palette) -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return (try? enc.encode(p)) ?? Data()
    }

    // MARK: TXT (.txt) – eine HEX-Zeile pro Farbe
    static func txt(_ p: Palette) -> Data {
        let lines = p.colors.map { $0.hex }.joined(separator: "\n")
        return Data((lines + "\n").utf8)
    }

    // MARK: Helfer
    static func slugify(_ s: String) -> String {
        let lower = s.lowercased()
        let mapped = lower.map { ch -> Character in
            (ch.isLetter || ch.isNumber) ? ch : "-"
        }
        let slug = String(mapped).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return slug.isEmpty ? "palette" : slug
    }
}

private extension Data {
    mutating func appendUInt16BE(_ v: UInt16) {
        append(UInt8((v >> 8) & 0xFF)); append(UInt8(v & 0xFF))
    }
    mutating func appendUInt32BE(_ v: UInt32) {
        appendUInt16BE(UInt16((v >> 16) & 0xFFFF)); appendUInt16BE(UInt16(v & 0xFFFF))
    }
    mutating func appendFloat32BE(_ f: Float) {
        appendUInt32BE(f.bitPattern)
    }
}
