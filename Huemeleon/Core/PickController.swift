//
//  PickController.swift
//  Huemeleon
//
//  Zentrale Pick-Logik. Nutzt Apples System-Lupe (NSColorSampler) für Einzel-Picks
//  und – in Schleife – für den Palette-Modus (Auto-Advance). Hält die aktuell
//  „fokussierte" Farbe, die das Color Wheel anzeigt.
//

import Observation
import AppKit

@MainActor
@Observable
final class PickController {
    let store: ColorStore

    /// Die fokussierte Farbe – das Color Wheel spiegelt sie.
    var current: PickedColor? {
        didSet { applyDockIcon() }
    }
    var isPicking = false

    // Palette
    var currentPalette: Palette?
    var isBuildingPalette = false
    /// Auswahl im separaten "All Palettes"-Fenster (nil = Liste).
    var allPalettesSelection: Palette?
    var buildingColors: [PickedColor] = []

    /// Vom Menüleisten-Fenster gesetzt: öffnet das Hauptfenster, wenn ein Palette-Build
    /// dort per Esc beendet wird (dann übernimmt RootView den Speichern-Dialog).
    @ObservationIgnored var openMainWindow: (() -> Void)?

    private let sampler: ColorSampler = SystemColorSampler()

    init(store: ColorStore) {
        self.store = store
        self.current = store.recentColors.first   // letzte gepickte Farbe der letzten Session
    }

    /// Einzel-Pick mit Apple-Systemlupe. Speichert + kopiert automatisch.
    func pick() {
        guard !isPicking, !isBuildingPalette else { return }
        isPicking = true
        Task {
            let picked = await sampler.pickOnce()
            isPicking = false
            guard let picked else { return }
            current = picked
            store.capture(picked)
        }
    }

    /// Setzt die fokussierte Farbe (z. B. aus dem Wheel oder Recent), optional in die Zwischenablage.
    func setCurrent(_ color: PickedColor, copy: Bool) {
        current = color
        if copy { store.recopy(color) }
    }

    /// Palette bauen ohne feste Anzahl: Apple-Lupe erscheint immer wieder, jede
    /// gepickte Farbe wird angehängt. Der Nutzer beendet mit Esc / Lupe-wegklicken
    /// (dann liefert pickOnce nil) -> Palette wird aus den gesammelten Farben erstellt.
    func buildPalette(name: String, openMainOnFinish: Bool = false) {
        guard !isPicking, !isBuildingPalette else { return }
        isBuildingPalette = true
        buildingColors = []
        let previous = current      // zum Wiederherstellen, falls ohne Pick abgebrochen wird
        current = nil               // frischer Start: „No color" / „---" bis zum ersten Pick
        Task {
            var first = true
            while true {
                if !first {
                    // kurze Pause, sonst kommt die System-Lupe nicht zuverlässig wieder
                    try? await Task.sleep(nanoseconds: 180_000_000)
                }
                first = false
                guard let picked = await sampler.pickOnce() else { break }   // Esc/Dismiss = Stopp
                buildingColors.append(picked)
                current = picked
            }
            let colors = buildingColors
            isBuildingPalette = false
            guard !colors.isEmpty else {
                current = previous  // nichts gepickt -> vorherige Farbe zurück, nichts geht verloren
                return
            }
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            currentPalette = Palette(name: trimmed.isEmpty ? "Palette" : trimmed, colors: colors)
            if openMainOnFinish { openMainWindow?() }   // Hauptfenster für den Speichern-Dialog
        }
    }

    func saveCurrentPalette() {
        guard let p = currentPalette else { return }
        store.savePalette(p)
    }

    func openPalette(_ p: Palette) {
        currentPalette = p
        current = p.colors.first
    }

    /// Aus der aktuellen Farbe eine neue Palette erstellen, speichern und im Detail öffnen.
    func newPaletteFromCurrent() {
        guard let c = current else { return }
        let p = Palette(name: "Palette", colors: [c])
        store.savePalette(p)
        currentPalette = p   // RootView öffnet daraufhin das Detail
    }

    /// Aktuelle Farbe an eine bestehende Palette anhängen.
    func addCurrentToPalette(_ id: UUID) {
        guard let c = current else { return }
        store.addColor(c, toPaletteID: id)
    }

    /// Dock-Icon in die aktuelle Farbe einfärben – oder auf das Standard-Icon
    /// zurücksetzen, wenn deaktiviert oder keine Farbe aktiv ist.
    func applyDockIcon() {
        guard store.tintDockIcon, let c = current,
              let img = AppIconTinter.shared.icon(for: c) else {
            NSApp.applicationIconImage = nil
            return
        }
        NSApp.applicationIconImage = img
    }
}
