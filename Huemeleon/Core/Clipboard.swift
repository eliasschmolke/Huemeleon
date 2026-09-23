//
//  Clipboard.swift
//  Huemeleon
//
//  Zwischenablage-Integration + konfigurierbare Ausgabeformate.
//

import AppKit

enum ClipboardFormat: String, CaseIterable, Codable, Identifiable {
    case hexHash    // #C47A32
    case hexPlain   // C47A32
    case rgb        // 196, 122, 50
    case rgba       // rgba(196, 122, 50, 1)
    case hsl        // hsl(28, 59%, 48%)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hexHash:  return "#RRGGBB"
        case .hexPlain: return "RRGGBB"
        case .rgb:      return "R, G, B"
        case .rgba:     return "RGBA"
        case .hsl:      return "HSL"
        }
    }

    func string(for c: PickedColor) -> String {
        switch self {
        case .hexHash:  return c.hex
        case .hexPlain: return String(c.hex.dropFirst())
        case .rgb:      let v = c.rgb255; return "\(v.r), \(v.g), \(v.b)"
        case .rgba:     let v = c.rgb255; return "rgba(\(v.r), \(v.g), \(v.b), 1)"
        case .hsl:      let v = c.hsl;    return "hsl(\(v.h), \(v.s)%, \(v.l)%)"
        }
    }
}

enum Clipboard {
    static func copy(_ c: PickedColor, as format: ClipboardFormat) {
        copyString(format.string(for: c))
    }

    static func copyString(_ s: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(s, forType: .string)
    }
}
