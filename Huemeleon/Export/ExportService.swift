//
//  ExportService.swift
//  Huemeleon
//
//  Speichert eine Palette über einen NSSavePanel im gewählten Format.
//

import AppKit
import UniformTypeIdentifiers

enum ExportService {
    @MainActor
    static func save(_ palette: Palette, as format: PaletteExportFormat) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(sanitizedFileName(palette.name)).\(format.fileExtension)"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        if let type = UTType(filenameExtension: format.fileExtension) {
            panel.allowedContentTypes = [type]
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try format.data(for: palette).write(to: url, options: .atomic)
            } catch {
                let alert = NSAlert(error: error)
                alert.messageText = "Export failed"
                alert.runModal()
            }
        }
    }

    private static func sanitizedFileName(_ name: String) -> String {
        let cleaned = name.components(separatedBy: CharacterSet(charactersIn: "/\\:")).joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Palette" : cleaned
    }
}
