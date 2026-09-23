# Huemeleon — Konzept & Architektur

> Ein kleines, schnelles, natives macOS-Utility zum systemweiten Farb-Picken
> und blitzschnellen Bauen von Farbpaletten.
>
> Leitprinzip: **Speed > Feature Count.** Kern: `Hover → Click → Copy`,
> bei Paletten `Click → Click → … → Export`.

---

## 0. Update — Redesign (aktueller Stand)

Nach den ersten Phasen wurde die Oberfläche neu ausgerichtet. Diese Entscheidungen
haben Vorrang vor abweichenden Details weiter unten:

- **Schlanke Hochkant-Fenster-App mit Dock-Icon** (fix ~300×600, `NavigationStack`,
  kein Sidebar). Aufbau je Seite von oben: Modus-Dropdown → HSV-Wheel + Helligkeitsregler
  → Farbwerte als kopierbare Zeilen → seiten­spezifischer Bereich → Button unten.
  Menüleisten-Icon (`MenuBarExtra`) bleibt als Schnellzugriff. App-Policy: `.regular`.
- **Picken über Apples System-Lupe** (`NSColorSampler`) — für Single *und* Palette
  (im Palette-Modus in Schleife = Auto-Advance). Der eigene ScreenCaptureKit-Overlay
  aus Phase 3 wurde **entfernt**; damit entfällt auch die Screen-Recording-Berechtigung.
- **HSV-Color-Wheel** im Stil des macOS-Farbwählers: Marker zeigt die aktuelle Farbe,
  Ziehen wählt Farbton/Sättigung, Regler die Helligkeit; darunter großer HEX + RGB/HSL.
- **Modus-Dropdown** (Pick / Palette) ganz oben.
- **Farbwerte als kopierbare Zeilen:** HEX, RGB, HSL und **CMYK** (Druck-Näherung ohne ICC).
- **Pick-Seite:** Wheel + Werte, letzte 8 Farben (2×4), unten „Pick".
- **Palette-Seite:** Wheel + Werte, letzte Paletten (Name + erste 4 Farben + Pfeil ins Detail),
  Größen-Slider, unten „Pick Palette"; frisch gebaute Palette öffnet das Detail (alle Farben,
  umbenennen, speichern, exportieren, löschen).
- Durchgehend natives Look & Feel (System-Controls, Materialien, SF-Typografie).

Unverändert gültig: Datenmodell, Clipboard/Formate, JSON-Persistenz, Recent Colors,
gespeicherte Paletten und die Exporte (ASE/GPL/CSS/JSON/TXT).

---

## 1. Produktidee in einem Satz

Huemeleon nimmt Farben von *irgendwo* auf dem Bildschirm auf (Website, Bild,
Photoshop, PDF …), zeigt sie live als HEX/RGB/HSL, kopiert sie automatisch in die
Zwischenablage und lässt daraus mit möglichst wenigen Klicks komplette Paletten
bauen und in die für Design-/Pixel-Workflows relevanten Formate exportieren.

## 2. Zielnutzer & Nicht-Ziele

**Zielnutzer:** eine Person (Design-/Grafik-Workflow, Illustrator/Photoshop/Aseprite).
Lokal, kein Account, keine Cloud.

**Bewusst NICHT (V1):** Color Wheels, CMYK, Pantone, ICC-Management, 20 Tabs,
Slider-Wüsten, überladene Settings. Es ist ein Utility, keine Color-Management-Suite.

## 3. Die zwei Kernmodi

### PICK (Einzelfarbe)
`Shortcut/Klick → Picker aktiv → Maus bewegen → Live-Preview + Lupe → Klick →
Farbe gespeichert → HEX automatisch im Clipboard → in Photoshop/Illustrator/Aseprite ⌘V`

### PALETTE (Palette bauen)
`Palette anlegen (z. B. 8 Farben) → Picking starten → Klick, Klick, Klick … →
Palette komplett → speichern → Export (ASE / GPL / …)`.
Zentral: **Auto-Advance** — nach jedem Klick wird automatisch der nächste Slot aktiv,
kein zusätzliches „Add Color". Eine 8-Farben-Palette = im Idealfall 8 Klicks.

---

## 4. Technische Architektur

### 4.1 Plattform
- Rein nativ: **Swift + SwiftUI**, **AppKit** dort wo Systemintegration nötig ist.
- Deployment Target: **macOS 26.2** (im Projekt gesetzt) → alle aktuellen APIs frei nutzbar.
- Kein Electron / Web / Cross-Platform.

### 4.2 App-Form: Menüleisten-Tool (MenuBarExtra) + optionales Fenster
Die App lebt in der Menüleiste (`MenuBarExtra`, `.menuBarExtraStyle(.window)`), das
Popover zeigt die kompakte vertikale UI. Ein globaler Shortcut startet den Pick, ohne
dass ein Fenster nötig ist. Für Paletten-Review/Export gibt es ein optionales
Hauptfenster.

**Warum:** passt am besten zu „so wenig Interaktion wie möglich". Kein Dock-Wechsel,
kein Fenster-Suchen. Die App verhält sich als *Accessory* (`NSApp.setActivationPolicy(.accessory)`),
also ohne Dock-Icon.

### 4.3 Das Herzstück: systemweites Pixel-Picking — zwei Engines hinter einem Protokoll

Das ist die wichtigste Architekturentscheidung. Es gibt zwei native Wege, und sie haben
komplementäre Stärken. Deshalb kapseln wir beide hinter **einem Protokoll**
(`ColorSampler`), sodass die UI nicht weiß, welche Engine gerade sampelt:

**Engine A — `NSColorSampler` (AppKit, seit macOS 10.15):**
Apples eingebaute System-Lupe. Ein Aufruf: `NSColorSampler().show { color in … }`.
- ✅ Keinerlei Berechtigung nötig (kein Screen-Recording-Prompt).
- ✅ Systemweit, alle Monitore, funktioniert sofort und zuverlässig.
- ✅ Native, vertraute Lupe „geschenkt".
- ❌ Einzelpick (kein Dauer-Hover), keine Kontrolle über die Lupen-UI, kein
  eigenes Live-Preview-Panel oder persistentes Palette-Overlay *während* des Sampelns.

**Engine B — `ScreenCaptureKit` (`SCScreenshotManager`, seit macOS 14):**
Moderner Screen-Capture. Wir greifen pro Mausbewegung einen kleinen Ausschnitt um den
Cursor und lesen den Pixel selbst.
- ✅ Volle Kontrolle: eigener Live-Preview, eigene Lupe, persistentes Palette-Overlay,
  Auto-Advance, Hotkeys 1–8 — der komplette gewünschte Palette-Workflow.
- ❌ Braucht die **Screen-Recording-Berechtigung** (`CGPreflightScreenCaptureAccess()` /
  `CGRequestScreenCaptureAccess()`), einmaliger System-Prompt.
- ⚠️ `CGDisplayCreateImage`/`CGWindowListCreateImage` sind seit macOS 15 **deprecated** —
  ScreenCaptureKit ist der korrekte, zukunftssichere Weg. Deshalb kein CoreGraphics-Legacy.

**Strategie:** MVP nutzt **Engine A** (sofort lauffähig, null Reibung). Der volle
Custom-Workflow (Palette-Auto-Advance, Custom-Lupe, Live-Panel, Overlay) läuft ab
Phase 3/4 auf **Engine B**. Beide bleiben austauschbar.

### 4.4 Overlay- & Event-Handling (für Engine B)
- Ein randloses, transparentes `NSPanel` (nonactivating, `level = .screenSaver`,
  `collectionBehavior` inkl. `.canJoinAllSpaces`) pro `NSScreen` deckt alle Monitore ab.
- Das Overlay empfängt `mouseMoved` (für Live-Preview + Lupe) und `mouseDown` (Capture).
- **Kein CGEventTap** → keine Accessibility-Berechtigung nötig. Escape/⌘Z über lokalen
  Key-Monitor, solange das Overlay aktiv ist.
- Retina/Backing-Scale (`NSScreen.backingScaleFactor`) und Multi-Monitor-Koordinaten
  werden beim Sampeln berücksichtigt.

### 4.5 Globaler Shortcut
Nativ, dependency-frei über einen dünnen Wrapper um Carbons `RegisterEventHotKey`
(die weiterhin sanktionierte API für echte systemweite Hotkeys). Default `⌘⇧C`,
später konfigurierbar. Kein externes Paket.

### 4.6 Zwischenablage
`NSPasteboard.general.clearContents(); setString(…, forType: .string)`.
Automatisch direkt nach dem Pick — **kein** zusätzlicher Copy-Button.
Format konfigurierbar; Default `#RRGGBB`.

### 4.7 Datenmodell (exportunabhängig)
Farben werden intern **unabhängig vom Exportformat** gehalten:
```
PickedColor { id, red, green, blue (0…1, sRGB), colorSpace, timestamp }
   → abgeleitet: hex, rgb255, hsl
Palette { id, name, colors: [PickedColor], slotCount, createdAt }
```
Beim Export wird daraus das jeweilige Zielformat erzeugt (reine Funktion
`Palette → Data` pro Exporter).

### 4.8 Persistenz
Einfache **Codable-JSON-Dateien** im Application-Support-Ordner
(`~/Library/Application Support/Huemeleon/`). Kein SwiftData, keine Migrationen.
Recent Colors + gespeicherte Paletten als JSON — portabel und exportnah.
Das SwiftData-Template (`Item.swift`, `ModelContainer`) wird entfernt.

### 4.9 Color Management (V1 bewusst schlicht)
Frage in V1: „Welche sichtbare Farbe liegt an diesem Pixel?" → sRGB → HEX/RGB.
`NSColor.usingColorSpace(.sRGB)` als gemeinsame Basis. **Wide-Gamut / Display-P3**
ist architektonisch offengehalten (`colorSpace`-Feld im Modell), aber nicht V1-Scope.

### 4.10 Farbwerte
- **HEX** (wichtigster Wert), **RGB**, **HSL** live.
- HSL wird aus sRGB berechnet (reine Utility-Funktion, testbar).

---

## 5. Export-Formate

Interne Palette → Exporter pro Format (jeweils reine, unit-testbare Funktion):

| Format | Zweck | Hinweis |
|---|---|---|
| **`.ase`** Adobe Swatch Exchange | Illustrator / Photoshop | Binärformat, RGB-Swatches |
| **`.gpl`** GIMP Palette | **Aseprite** & GIMP | Klartext, von Aseprite nativ im-/exportiert — der zuverlässige Aseprite-Weg |
| **`.css`** | Web | `:root { --color-1: #…; }` oder Klassenliste |
| **`.json`** | eigenes/Tooling | volles internes Modell |
| **`.txt`** | universell | eine HEX-Zeile pro Farbe |
| *(später)* `.png` | Aseprite/Pixel | 1px-Zeile indizierter Farben |

### Wichtig: `.ase`-Doppeldeutigkeit
Im Aseprite-Umfeld ist die Endung `.ase` doppeldeutig — historisch war `.ase`
*Aseprites eigenes Sprite-Format*, gleichzeitig meint `.ase` das *Adobe Swatch
Exchange*-Palettenformat. Um Verwirrung zu vermeiden, trennen wir sauber:
- **`.ase` → Adobe Swatch Exchange** (für Illustrator/Photoshop).
- **`.gpl` → für Aseprite** (Aseprite importiert GPL zuverlässig als Palette).

So bekommt Aseprite ein eindeutiges, gut unterstütztes Format und Illustrator sein ASE,
ohne Endungs-Kollision. (Recherche: Aseprites Paletten-Extension-System basiert selbst
auf `.gpl`; ASE-Support für Aseprite existiert nur über Community-Scripts.)

---

## 6. UI / Design

Kompakt, vertikal (schmales Hochformat), klare Typografie, große Farbvorschau,
wenig Text, wenig UI. Orientierung an modernen nativen macOS-Utilities, ohne eine
bestehende App zu kopieren.

Popover-Struktur (Richtung):
```
┌───────────────────────┐
│  PICK   PALETTE       │   ← Segmented, PICK aktiv
│  ────                 │
│      ███████          │   ← große Vorschau letzte Farbe
│      ███████          │
│      #C47A32          │   ← HEX groß (Klick = kopieren)
│      RGB 196 122 50   │
│      HSL 28 59% 48%   │
│   [ Pick Color ]  ⌘⇧C │
│  Recent               │
│  ● ● ● ● ● ●          │   ← Klick = als aktuell + Clipboard
└───────────────────────┘
```
Klick auf HEX oder eine Recent-Farbe kopiert erneut in die Zwischenablage.

---

## 7. Keyboard / Workflow-Details

- Global: `⌘⇧C` → Picker aktivieren.
- Palette-Mode: Auto-Advance ist Default; optional Ziffern `1…N` für gezielten Slot,
  `Esc` = Picking abbrechen, `⌘Z` = letzte gepickte Farbe rückgängig (Slot wieder frei).
- Alles ohne Tastatur bedienbar; Hotkeys sind Ergänzung, nicht Pflicht.

## 8. Recent Colors & gespeicherte Paletten

- **Recent:** bewusst klein (8–12 Einträge), Klick = wieder aktuell + Clipboard.
- **My Palettes:** Name, beliebig viele Farben, wieder öffnen, einzelne Farbe kopieren,
  erneut exportieren.

---

## 9. Architektur für die Zukunft offenhalten (NICHT V1)

- **Dominant Colors:** Bildbereich wählen → dominante Farben extrahieren
  (später eigene Engine; das `ColorSampler`-Protokoll erlaubt eine `RegionSampler`-Erweiterung).
- **App-spezifische Output-Formate:** Photoshop `#…`, CSS `rgb(…)`, Swift `Color(red:…)`,
  Figma `C47A32` — nur als weiteres `ClipboardFormat`/Exporter-Case, Modell bleibt gleich.
- **Wide-Gamut / P3:** `colorSpace`-Feld existiert bereits.

Diese Punkte werden **nur architektonisch** offengehalten und blähen V1 nicht auf.

## 10. Berechtigungen & Sandbox

- **Engine A (NSColorSampler):** keine Berechtigung nötig — deshalb ideal für den MVP.
- **Engine B (ScreenCaptureKit):** einmaliger Screen-Recording-Prompt.
- **Global Hotkey (Carbon):** keine Accessibility-Berechtigung nötig.
- Da es ein persönliches Tool ist (kein App Store), kann die App-Sandbox bei Bedarf
  deaktiviert werden, um Reibung zu minimieren; ScreenCaptureKit funktioniert aber
  auch sandboxed.

## 11. Modul-/Datei-Struktur (Zielbild)

```
Huemeleon/
  HuemeleonApp.swift        App-Entry, MenuBarExtra, AppDelegate (Accessory)
  Core/
    PickedColor.swift       Farbmodell + HEX/RGB/HSL
    Palette.swift           Palettenmodell
    ColorMath.swift         RGB↔HSL etc.
    ColorSampler.swift      Protokoll
    SystemColorSampler.swift    Engine A (NSColorSampler)
    ScreenCaptureSampler.swift  Engine B (ScreenCaptureKit)  [ab Phase 3]
    Clipboard.swift         NSPasteboard + Formate
    HotKey.swift            Carbon RegisterEventHotKey-Wrapper [Phase 5+]
    ColorStore.swift        @Observable, JSON-Persistenz
  Features/
    MenuBar/MenuBarView.swift
    Pick/PickPanel.swift        Overlay/Lupe/Live-Preview [Phase 3]
    Palette/PaletteView.swift   Review + Export [Phase 4]
  Export/
    Exporter.swift          Protokoll
    GPLExporter.swift / ASEExporter.swift / CSSExporter.swift / …  [Phase 6]
```

## 12. Verifikation

- `ColorMath` (RGB↔HSL, HEX) und alle Exporter sind reine Funktionen → **Unit-Tests**
  (das vorhandene HuemeleonTests-Target).
- Exporte gegen echte Zielprogramme prüfen: `.gpl` in Aseprite importieren,
  `.ase` in Illustrator öffnen.
