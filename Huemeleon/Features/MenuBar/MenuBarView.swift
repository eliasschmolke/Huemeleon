//
//  MenuBarView.swift
//  Huemeleon
//
//  Menu-bar quick access: current color block, full value panel, recents
//  (colors or last palette), open-window and pick.
//

import SwiftUI

struct MenuBarView: View {
    @Environment(ColorStore.self) private var store
    @Environment(PickController.self) private var controller
    @Environment(\.openWindow) private var openWindow

    private enum RecentTab: String, CaseIterable, Identifiable {
        case colors = "Colors", palettes = "Palettes"
        var id: String { rawValue }
    }
    @State private var recentTab: RecentTab = .colors

    private var focus: PickedColor { controller.current ?? PickedColor(red: 1, green: 1, blue: 1) }

    var body: some View {
        VStack(spacing: 12) {
            modeSwitch
            colorBlock
            ColorValuesView(color: controller.current)
            if controller.isBuildingPalette { buildingView } else { recents }

            pickButton

            footer
        }
        .padding(14)
        .frame(width: 250)
    }

    // Live-Picking-Ansicht während ein Palette-Build läuft (sichtbar, solange das
    // Popover offen ist – macOS schließt es aber, sobald die Lupe erscheint).
    private var buildingView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(controller.buildingColors.count) colors · Esc to finish")
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 6), spacing: 5) {
                ForEach(controller.buildingColors) { c in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(c.swiftUIColor).frame(height: 20)
                        .overlay { RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(.black.opacity(0.1)) }
                }
            }
        }
    }

    // Primärer Button unten: je nach Tab Farbe oder Palette picken.
    @ViewBuilder private var pickButton: some View {
        Group {
            if controller.isBuildingPalette {
                Button {} label: {
                    Label("Picking palette… Esc to finish", systemImage: "eyedropper.halffull")
                        .frame(maxWidth: .infinity)
                }
                .disabled(true)
            } else if recentTab == .palettes {
                Button {
                    controller.openMainWindow = {
                        openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true)
                    }
                    controller.buildPalette(name: "", openMainOnFinish: true)
                } label: {
                    Label("Pick Palette", systemImage: "square.stack.3d.up")
                        .frame(maxWidth: .infinity)
                }
            } else {
                Button { controller.pick() } label: {
                    Label("Pick Color", systemImage: "eyedropper").frame(maxWidth: .infinity)
                }
                .disabled(controller.isPicking)
            }
        }
        .controlSize(.large).buttonStyle(.borderedProminent)
    }

    private var colorBlock: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(controller.current?.swiftUIColor ?? Color(nsColor: .quaternaryLabelColor))
            .frame(height: 64)
            .overlay { if controller.current == nil { Text("No color").font(.caption).foregroundStyle(.secondary) } }
            .overlay { RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.black.opacity(0.1)) }
    }

    // MARK: Recents (colors / last palette)

    // Modus-Umschalter ganz oben – steuert Recents-Inhalt UND den Pick-Button unten.
    private var modeSwitch: some View {
        GlassSegmented(options: RecentTab.allCases, title: { $0.rawValue }, selection: $recentTab, height: 26)
    }

    @ViewBuilder private var recents: some View {
        switch recentTab {
        case .colors:   recentColors
        case .palettes: recentPalettes
        }
    }

    private var recentColors: some View {
        Group {
            if store.recentColors.isEmpty {
                Text("No colors yet.").font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                    ForEach(Array(store.recentColors.prefix(8))) { c in
                        Button { controller.setCurrent(c, copy: true) } label: {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(c.swiftUIColor).frame(height: 26)
                                .overlay { RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(.black.opacity(0.1)) }
                        }
                        .buttonStyle(.plain).help(c.hex)
                    }
                }
            }
        }
    }

    @ViewBuilder private var recentPalettes: some View {
        VStack(spacing: 8) {
            if let p = store.savedPalettes.first {
                Button { openPalette(p) } label: { paletteCard(p) }
                    .buttonStyle(.plain)
            } else {
                Text("No palettes yet.").font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button { openAllList() } label: {
                Label("All Palettes", systemImage: "square.grid.2x2").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered).controlSize(.small)
        }
    }

    private func paletteCard(_ p: Palette) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(p.name).font(.caption).fontWeight(.medium).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 4) {
                ForEach(Array(p.colors.prefix(8))) { c in
                    RoundedRectangle(cornerRadius: 4).fill(c.swiftUIColor).frame(height: 20)
                }
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.black.opacity(0.08)))
        .contentShape(Rectangle())
    }

    private func openPalette(_ p: Palette) {
        controller.allPalettesSelection = p
        openWindow(id: "all-palettes"); NSApp.activate(ignoringOtherApps: true)
    }

    private func openAllList() {
        controller.allPalettesSelection = nil
        openWindow(id: "all-palettes"); NSApp.activate(ignoringOtherApps: true)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(spacing: 12) {
                SettingsLink { Image(systemName: "gearshape") }
                    .buttonStyle(.borderless).help("Settings")
                Button {
                    openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true)
                } label: { Image(systemName: "macwindow") }
                    .buttonStyle(.borderless).help("Open Window")
                Text(store.shortcutDisplay).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
