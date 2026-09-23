//
//  ColorStore.swift
//  Huemeleon
//
//  Zentraler Zustand + JSON-Persistenz (Application Support).
//  Kein SwiftData – bewusst simpel.
//

import SwiftUI
import Observation

@Observable
final class ColorStore {
    private(set) var recentColors: [PickedColor] = []
    private(set) var savedPalettes: [Palette] = []
    var clipboardFormat: ClipboardFormat = .hexHash {
        didSet { save() }
    }
    /// Farbe beim Picken automatisch in die Zwischenablage kopieren.
    var autoCopy: Bool = true {
        didSet { save() }
    }
    /// Dock-Icon live in die aktuell gepickte Farbe einfärben (Glas-Optik bleibt).
    var tintDockIcon: Bool = true {
        didSet { save(); onTintChange?() }
    }

    // Globaler Shortcut (Carbon keyCode + modifiers) + Anzeige.
    private(set) var shortcutKeyCode: UInt32 = 8       // 'C'
    private(set) var shortcutModifiers: UInt32 = 768   // cmd(256)+shift(512)
    private(set) var shortcutDisplay: String = "⌘⇧C"
    @ObservationIgnored var onShortcutChange: (() -> Void)?
    /// Wird gerufen, wenn der Dock-Tint-Schalter umgelegt wird.
    @ObservationIgnored var onTintChange: (() -> Void)?

    private let maxRecent = 12

    // MARK: Persistenz

    private struct Persisted: Codable {
        var recentColors: [PickedColor]
        var clipboardFormat: ClipboardFormat
        var useSystemPicker: Bool?    // optional -> ältere store.json bleibt lesbar
        var savedPalettes: [Palette]? // dito
        var autoCopy: Bool?           // dito
        var shortcutKeyCode: UInt32?
        var shortcutModifiers: UInt32?
        var shortcutDisplay: String?
        var tintDockIcon: Bool?
    }

    private static var fileURL: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Huemeleon", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("store.json")
    }

    init() { load() }

    /// Neue Farbe aufnehmen: nach vorne, Duplikate raus, kürzen, in Clipboard.
    func capture(_ color: PickedColor) {
        recentColors.removeAll { $0.hex == color.hex }
        recentColors.insert(color, at: 0)
        if recentColors.count > maxRecent {
            recentColors = Array(recentColors.prefix(maxRecent))
        }
        if autoCopy { Clipboard.copy(color, as: clipboardFormat) }
        save()
    }

    /// Recent-Farbe erneut kopieren.
    func recopy(_ color: PickedColor) {
        Clipboard.copy(color, as: clipboardFormat)
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let p = try? JSONDecoder().decode(Persisted.self, from: data) else { return }
        recentColors = p.recentColors
        clipboardFormat = p.clipboardFormat
        savedPalettes = p.savedPalettes ?? []
        autoCopy = p.autoCopy ?? true
        shortcutKeyCode = p.shortcutKeyCode ?? 8
        shortcutModifiers = p.shortcutModifiers ?? 768
        shortcutDisplay = p.shortcutDisplay ?? "⌘⇧C"
        tintDockIcon = p.tintDockIcon ?? true
    }

    private func save() {
        let p = Persisted(recentColors: recentColors,
                          clipboardFormat: clipboardFormat,
                          useSystemPicker: nil,
                          savedPalettes: savedPalettes,
                          autoCopy: autoCopy,
                          shortcutKeyCode: shortcutKeyCode,
                          shortcutModifiers: shortcutModifiers,
                          shortcutDisplay: shortcutDisplay,
                          tintDockIcon: tintDockIcon)
        guard let data = try? JSONEncoder().encode(p) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }

    // MARK: Paletten

    func savePalette(_ palette: Palette) {
        if let i = savedPalettes.firstIndex(where: { $0.id == palette.id }) {
            savedPalettes[i] = palette
        } else {
            savedPalettes.insert(palette, at: 0)
        }
        save()
    }

    func deletePalette(_ palette: Palette) {
        savedPalettes.removeAll { $0.id == palette.id }
        save()
    }

    func isSaved(_ palette: Palette) -> Bool {
        savedPalettes.contains { $0.id == palette.id }
    }

    /// Farbe an eine bestehende, gespeicherte Palette anhängen.
    func addColor(_ color: PickedColor, toPaletteID id: UUID) {
        guard let i = savedPalettes.firstIndex(where: { $0.id == id }) else { return }
        savedPalettes[i].colors.append(color)
        save()
    }

    func setShortcut(keyCode: UInt32, modifiers: UInt32, display: String) {
        shortcutKeyCode = keyCode
        shortcutModifiers = modifiers
        shortcutDisplay = display
        save()
        onShortcutChange?()
    }
}
