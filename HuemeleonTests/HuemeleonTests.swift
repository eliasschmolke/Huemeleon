//
//  HuemeleonTests.swift
//  HuemeleonTests
//

import Testing
@testable import Huemeleon

struct HuemeleonTests {

    @Test func hexFromComponents() {
        let c = PickedColor(red: 196.0/255, green: 122.0/255, blue: 50.0/255)
        #expect(c.hex == "#C47A32")
        #expect(c.rgb255 == (196, 122, 50))
    }

    @Test func hslPrimaries() {
        let red = ColorMath.rgbToHSL(r: 1, g: 0, b: 0)
        #expect(Int(red.h.rounded()) == 0)
        #expect(Int((red.s * 100).rounded()) == 100)
        #expect(Int((red.l * 100).rounded()) == 50)

        let white = ColorMath.rgbToHSL(r: 1, g: 1, b: 1)
        #expect(Int((white.s * 100).rounded()) == 0)
        #expect(Int((white.l * 100).rounded()) == 100)
    }

    @Test func clipboardFormats() {
        let c = PickedColor(red: 196.0/255, green: 122.0/255, blue: 50.0/255)
        #expect(ClipboardFormat.hexHash.string(for: c) == "#C47A32")
        #expect(ClipboardFormat.hexPlain.string(for: c) == "C47A32")
        #expect(ClipboardFormat.rgb.string(for: c) == "196, 122, 50")
    }

    // MARK: Export

    private var sample: Palette {
        Palette(name: "Test", colors: [
            PickedColor(red: 196.0/255, green: 122.0/255, blue: 50.0/255),
            PickedColor(red: 0, green: 0, blue: 0),
            PickedColor(red: 1, green: 1, blue: 1)
        ])
    }

    @Test func gplExport() {
        let text = String(decoding: PaletteExportFormat.gpl.data(for: sample), as: UTF8.self)
        #expect(text.hasPrefix("GIMP Palette"))
        #expect(text.contains("Name: Test"))
        #expect(text.contains("196 122  50"))
        #expect(text.contains("#C47A32"))
    }

    @Test func txtExport() {
        let text = String(decoding: PaletteExportFormat.txt.data(for: sample), as: UTF8.self)
        #expect(text == "#C47A32\n#000000\n#FFFFFF\n")
    }

    @Test func cssExport() {
        let text = String(decoding: PaletteExportFormat.css.data(for: sample), as: UTF8.self)
        #expect(text.contains("--test-1: #C47A32;"))
        #expect(text.contains(":root {"))
    }

    @Test func jsonExportRoundTrips() throws {
        let data = PaletteExportFormat.json.data(for: sample)
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        let back = try dec.decode(Palette.self, from: data)
        #expect(back.colors.count == 3)
        #expect(back.colors.first?.hex == "#C47A32")
    }

    @Test func aseHeaderAndBlockCount() {
        let d = PaletteExportFormat.ase.data(for: sample)
        #expect(Array(d.prefix(4)) == Array("ASEF".utf8))
        // Blockanzahl steht als UInt32 Big-Endian ab Byte 8 (Group-Start + 3 Farben + Group-End = 5)
        let b = Array(d)
        let count = (UInt32(b[8]) << 24) | (UInt32(b[9]) << 16) | (UInt32(b[10]) << 8) | UInt32(b[11])
        #expect(count == 5)
    }
}
