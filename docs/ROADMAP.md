# Huemeleon — Phasenplan

Prinzip: schrittweise, jede Phase ist für sich lauffähig und in Xcode baubar.
Nicht sofort eine riesige Codebasis. Nach jeder Phase: bauen, testen, dann weiter.

Legende: ✅ erledigt · 🔜 als Nächstes · ⬜ geplant

---

## Phase 0 — Machbarkeit (✅ geklärt)
- [x] Systemweites Picking technisch verifiziert: `NSColorSampler` (sofort, ohne
      Berechtigung) und `ScreenCaptureKit` (`SCScreenshotManager`) als Custom-Weg.
- [x] Aseprite-Format recherchiert → `.gpl` als zuverlässiger Weg; `.ase` = Adobe Swatch
      Exchange für Illustrator (Endungs-Doppeldeutigkeit sauber getrennt).
- [x] Architektur- und Technikentscheidungen festgehalten (siehe CONCEPT.md).

## Phase 1 — MVP: Single Pick → Clipboard (✅ im Projekt)
Ziel: Ein wirklich funktionierendes, minimales Tool.
- [x] Template aufgeräumt: SwiftData / `Item.swift` / `ContentView.swift` raus.
- [x] `MenuBarExtra`-Grundgerüst, App als Accessory (kein Dock-Icon).
- [x] `ColorSampler`-Protokoll + `SystemColorSampler` (NSColorSampler-Engine).
- [x] `PickedColor` mit HEX/RGB/HSL, `ColorMath` (RGB↔HSL).
- [x] `Clipboard` mit Formaten (`#RRGGBB`, `RRGGBB`, `R, G, B`, HSL); Default `#RRGGBB`.
- [x] Auto-Copy direkt nach Pick.
- [x] `ColorStore` (@Observable) + Recent Colors, JSON-Persistenz in Application Support.
- [x] Kompaktes Popover: Vorschau, HEX/RGB/HSL, „Pick Color", Recent-Reihe.
- **Build-Test:** In Xcode Run → Menüleisten-Icon → „Pick Color" → Lupe → Klick → HEX im Clipboard.

## Phase 2 — Feinschliff Single Pick + globaler Shortcut (✅ im Projekt)
- [x] Carbon-`RegisterEventHotKey`-Wrapper (`HotKey.swift`), Default `⌘⇧C` → Pick.
- [x] Gemeinsamer `PickController` für Popover UND Hotkey.
- [x] Clipboard-Format umschaltbar (Menü im Popover), persistiert.
- [x] Klick auf HEX / Recent-Farbe kopiert erneut.
- [x] Fußzeile mit Shortcut-Hinweis + **Beenden** (Quit für die Accessory-App).
- [ ] Später: konfigurierbarer Shortcut (aktuell fest `⌘⇧C`) → Phase 7.
- **Build-Test:** App läuft, in Xcode Run → irgendwo `⌘⇧C` drücken → Lupe erscheint → Klick → HEX im Clipboard, ganz ohne Popover.

## Phase 3 — Custom-Picker mit Live-Preview + Lupe (ScreenCaptureKit) (✅ im Projekt)
- [x] Screen-Recording-Berechtigung: `CGPreflight/CGRequestScreenCaptureAccess` (`ScreenCapturePermission.swift`).
- [x] `ScreenCaptureSampler` (Engine B) + `PickOverlayController`: kleiner Ausschnitt um den
      Cursor via `SCScreenshotManager`, Mittel-Pixel nach sRGB gelesen (Backing-Scale, Multi-Monitor).
- [x] Transparentes Overlay-Fenster über alle Bildschirme, Klick = picken.
- [x] Live-Lupe am Cursor (~60 fps) mit markiertem Mittel-Pixel, ohne Self-Capture-Feedback.
- [x] Live-Vorschau-Panel (Farbfeld + HEX + RGB) an der Lupe.
- [x] `Esc` = abbrechen.
- [x] Umschalter „System-Lupe verwenden" (Fallback ohne Berechtigung) im Popover-Menü.
- ⚠️ Zu prüfen beim ersten Run: Cursor→Display-Koordinaten des `sourceRect` (Multi-Monitor/Retina)
      — ggf. minimal justieren, falls die Lupe einen leicht versetzten Bereich zeigt.

## Phase 4 — Palette Mode (✅ im Projekt)
- [x] PALETTE-Tab im Popover: Name + Farbzahl (Presets 4/5/6/8/10/12 + Stepper 2…32).
- [x] Overlay-Session bleibt offen, Picking mit **Auto-Advance** (Klick → nächster leerer Slot).
- [x] Fortschritts-HUD oben auf dem aktiven Bildschirm (`● ● ○ …`, „3 / 8", aktiver Slot geringelt).
- [x] Hotkeys `1…9` = aktuelle Farbe in diesen Slot; `⌘Z` = letzte Farbe rückgängig; `Esc` = beenden.
- [x] Alle Slots gefüllt → Session endet automatisch → Review-Fenster.
- [x] Review-Fenster (`Window`-Scene): Farbfelder + HEX-Liste, Klick auf Feld = kopieren.
- [ ] Dauerhaft speichern/benennen → Phase 5; Export-Button noch deaktiviert → Phase 6.

## Phase 5 — Lokale Speicherung der Paletten (✅ im Projekt)
- [x] `savedPalettes` in `ColorStore`, als JSON in Application Support (rückwärtskompatibel).
- [x] Review: „Speichern"/„Aktualisieren", Umbenennen (Namensfeld), „Löschen".
- [x] „MY PALETTES"-Liste im Popover (PALETTE-Tab): Vorschau + Name, Klick öffnet im Review,
      Rechtsklick → Löschen.

## Phase 6 — Export (✅ im Projekt)
- [x] Reine Exporter (`PaletteExport`): `.gpl` (Aseprite/GIMP), `.ase` (Adobe Swatch Exchange, binär),
      `.css`, `.json`, `.txt`.
- [x] `ExportService` mit `NSSavePanel`; Export-Menü im Review aktiv.
- [x] Build-Setting `ENABLE_USER_SELECTED_FILES = readwrite` (Sandbox durfte sonst nicht schreiben).
- [x] Unit-Tests für GPL/CSS/TXT/JSON + ASE-Header/Blockanzahl.
- [ ] **Verifikation durch dich:** `.gpl` in Aseprite importieren, `.ase` in Illustrator öffnen.

## Phase 7 — Redesign auf native Fenster-App (✅ im Projekt)
- [x] Fenster-App mit Dock-Icon (`.regular`) als primäre UI; Menüleiste = Schnellzugriff.
- [x] `NavigationSplitView`: Seitenleiste (Zuletzt + Paletten) + Detail.
- [x] Umstieg auf Apple-Systemlupe (`NSColorSampler`) für Single **und** Palette (Schleife/Auto-Advance);
      eigener ScreenCaptureKit-Overlay + Screen-Recording-Berechtigung entfernt.
- [x] HSV-Color-Wheel (macOS-Farbwähler-Stil) mit Marker, Ziehen = Farbton/Sättigung, Regler = Helligkeit.
- [x] Modus-Dropdown (Pick / Palette) statt Tabs.
- [x] HSV-Mathematik ergänzt (`ColorMath.rgbToHSV`/`hsvToRGB`).
- [x] Schlankes Hochkant-Fenster (fix ~300×600, `NavigationStack`, kein Sidebar).
- [x] Kopierbare Werte-Zeilen inkl. **CMYK** (`ColorMath.rgbToCMYK`, Druck-Näherung).
- [x] Pick: Recent als 2×4. Palette: letzte Paletten als Zeilen + Detail-Push, Größen-Slider.

## Phase 8 — Feinschliff & Settings ⬜
- [ ] Konfigurierbarer globaler Shortcut (aktuell fest `⌘⇧C`).
- [ ] Einzelne Palettenfarbe gezielt neu picken (Slot ersetzen).
- [ ] Optional: Launch at Login, Fenster-Zustände, Animationen.

## Später (NICHT V1 — nur offengehalten)
- [ ] Dominant Colors aus Bildbereich.
- [ ] App-spezifische Output-Formate (Photoshop/CSS/Swift/Figma).
- [ ] Wide-Gamut / Display-P3.

---

### Faustregel bei jedem Feature
Braucht es drei zusätzliche Klicks? Dann prüfen, ob es überhaupt nötig ist.
Kern bleibt: `Hover → Click → Copy` und `Click → … → Export`.
