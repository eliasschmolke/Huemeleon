//
//  ColorSampler.swift
//  Huemeleon
//
//  Protokoll für Farb-Sampling. Aktuelle Engine: SystemColorSampler (Apples
//  NSColorSampler-Systemlupe). Das Protokoll hält die Tür für weitere Engines offen.
//

import AppKit

@MainActor
protocol ColorSampler {
    /// Aktiviert das systemweite Picken und liefert genau eine Farbe (oder nil bei Abbruch).
    func pickOnce() async -> PickedColor?
}

/// MVP-Engine: Apples eingebaute System-Lupe. Keine Berechtigung nötig.
struct SystemColorSampler: ColorSampler {
    func pickOnce() async -> PickedColor? {
        await withCheckedContinuation { continuation in
            NSColorSampler().show { nsColor in
                guard let nsColor, let picked = PickedColor(nsColor: nsColor) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: picked)
            }
        }
    }
}
