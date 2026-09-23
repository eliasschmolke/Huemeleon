//
//  RootView.swift
//  Huemeleon
//
//  Slim vertical window. Top: mode dropdown + settings. All navigation (palette
//  detail, all-palettes list) happens inside this same window.
//

import SwiftUI

struct RootView: View {
    @Environment(PickController.self) private var controller
    @Environment(ColorStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    enum Mode: String, CaseIterable, Identifiable {
        case single = "Pick", palette = "Palette"
        var id: String { rawValue }
    }
    @State private var mode: Mode = .single
    @State private var detailPalette: Palette?
    @State private var detailIsNew = false
    @State private var showAllList = false
    @State private var allSelectMode = false
    @State private var allSelectedIDs: Set<UUID> = []

    // Slider-Größe hier anpassen:
    private let sliderWidth: CGFloat = 190
    private let sliderHeight: CGFloat = 28

    var body: some View {
        Group {
            if let p = detailPalette {
                PaletteDetailView(palette: p, isNew: detailIsNew) { detailPalette = nil }
            } else if showAllList {
                allPalettesScreen
            } else {
                home
            }
        }
        // Fensterbreite: min 300, max 340 (hier anpassen). Höhe frei ausziehbar.
        .frame(minWidth: 300, idealWidth: 300, maxWidth: 350,
               minHeight: 560, idealHeight: 600, maxHeight: 2000)
        .onChange(of: controller.currentPalette) { _, new in
            if let new { detailIsNew = true; detailPalette = new; controller.currentPalette = nil }
        }
        .onAppear {
            // Fenster wurde ggf. gerade erst (per Menü-Palette-Pick) geöffnet – dann
            // liegt currentPalette schon vor und onChange feuert nicht mehr.
            if let p = controller.currentPalette {
                detailIsNew = true; detailPalette = p; controller.currentPalette = nil
            }
        }
    }

    // MARK: Home

    private var home: some View {
        VStack(spacing: 16) {
            HStack {
                modeSlider
                Spacer()
                SettingsLink { Image(systemName: "gearshape") }
                    .buttonStyle(.borderless)
                    .help("Settings")
            }

            if mode == .single {
                PickPageView()
            } else {
                PalettePageView(onOpen: { detailIsNew = false; detailPalette = $0 }, onShowAll: { showAllList = true })
            }
        }
        .padding(16)
    }

    private var modeSlider: some View {
        GlassSegmented(options: Mode.allCases, title: { $0.rawValue }, selection: $mode,
                       width: sliderWidth, height: sliderHeight)
    }

    // MARK: All palettes (in-window)

    private var allPalettesScreen: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    showAllList = false; allSelectMode = false; allSelectedIDs.removeAll()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain).help("Back")

                Text("All Palettes").font(.title3).fontWeight(.semibold)
                Spacer()

                if !store.savedPalettes.isEmpty {
                    Button(allSelectMode ? "Done" : "Select") {
                        withAnimation(.snappy) {
                            allSelectMode.toggle()
                            if !allSelectMode { allSelectedIDs.removeAll() }
                        }
                    }
                    .buttonStyle(.plain).foregroundStyle(.tint)
                }

                Button {
                    controller.allPalettesSelection = nil
                    openWindow(id: "all-palettes")
                } label: {
                    Image(systemName: "macwindow.badge.plus")
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain).help("Open in separate window")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)

            PaletteGridList(onOpen: { detailIsNew = false; detailPalette = $0 },
                            selectMode: $allSelectMode, selectedIDs: $allSelectedIDs)
        }
    }
}
