//
//  Palette.swift
//  Huemeleon
//
//  Palettenmodell – exportunabhängig.
//

import Foundation

struct Palette: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var colors: [PickedColor]
    var createdAt: Date = Date()

    /// Übliche Presets für die Slot-Anzahl (intern beliebig).
    static let presetCounts = [4, 5, 6, 8, 10, 12]
}
