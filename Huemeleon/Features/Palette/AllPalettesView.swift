//
//  AllPalettesView.swift
//  Huemeleon
//
//  Reusable list of all saved palettes (PaletteGridList) with an Apple-style
//  multi-select edit mode (selection circle on the left, rows slide right), plus
//  the pop-out window wrapper.
//

import SwiftUI

/// Scrollable list of every saved palette. In select mode each row shows a
/// selection circle and can be batch-deleted.
struct PaletteGridList: View {
    @Environment(ColorStore.self) private var store
    var onOpen: (Palette) -> Void
    @Binding var selectMode: Bool
    @Binding var selectedIDs: Set<UUID>

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if store.savedPalettes.isEmpty {
                    ContentUnavailableView("No Palettes",
                                           systemImage: "swatchpalette",
                                           description: Text("Create a palette in the main window and save it."))
                        .frame(minHeight: 320)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(store.savedPalettes) { p in row(p) }
                    }
                    .padding(16)
                    .thinScrollBars()
                }
            }

            if selectMode && !store.savedPalettes.isEmpty {
                Divider()
                HStack {
                    Text("\(selectedIDs.count) selected").font(.callout).foregroundStyle(.secondary)
                    Spacer()
                    Button(role: .destructive) { deleteSelected() } label: { Label("Delete", systemImage: "trash") }
                        .disabled(selectedIDs.isEmpty)
                }
                .padding(12)
            }
        }
    }

    private func row(_ p: Palette) -> some View {
        let selected = selectedIDs.contains(p.id)
        return HStack(spacing: 12) {
            if selectMode {
                Group {
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.palette).foregroundStyle(.white, Color.accentColor)
                    } else {
                        Image(systemName: "circle").foregroundStyle(.secondary)
                    }
                }
                .font(.title2)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            card(p)
        }
        .contentShape(Rectangle())
        .onTapGesture { if selectMode { toggle(p) } else { onOpen(p) } }
        .contextMenu {
            Button(role: .destructive) { store.deletePalette(p) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func card(_ p: Palette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(p.name).font(.headline)
                Spacer()
                Text("\(p.colors.count) colors").font(.caption).foregroundStyle(.secondary)
                if !selectMode {
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 4) {
                ForEach(Array(p.colors.prefix(8))) { c in
                    RoundedRectangle(cornerRadius: 4).fill(c.swiftUIColor).frame(height: 18)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.black.opacity(0.08)))
    }

    private func toggle(_ p: Palette) {
        if selectedIDs.contains(p.id) { selectedIDs.remove(p.id) } else { selectedIDs.insert(p.id) }
    }

    private func deleteSelected() {
        let toDelete = store.savedPalettes.filter { selectedIDs.contains($0.id) }
        toDelete.forEach { store.deletePalette($0) }
        selectedIDs.removeAll()
    }
}

/// Separate pop-out window: header (title + Select) and the list; palette detail
/// selection is shared via the controller.
struct AllPalettesView: View {
    @Environment(PickController.self) private var controller
    @Environment(ColorStore.self) private var store

    @State private var selectMode = false
    @State private var selectedIDs: Set<UUID> = []

    var body: some View {
        Group {
            if let p = controller.allPalettesSelection {
                PaletteDetailView(palette: p) { controller.allPalettesSelection = nil }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("All Palettes").font(.title3).fontWeight(.semibold)
                        Spacer()
                        if !store.savedPalettes.isEmpty {
                            Button(selectMode ? "Done" : "Select") {
                                withAnimation(.snappy) {
                                    selectMode.toggle()
                                    if !selectMode { selectedIDs.removeAll() }
                                }
                            }
                            .buttonStyle(.plain).foregroundStyle(.tint)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12).frame(minHeight: 44)

                    PaletteGridList(onOpen: { controller.allPalettesSelection = $0 },
                                    selectMode: $selectMode, selectedIDs: $selectedIDs)
                }
            }
        }
        .frame(minWidth: 360, idealWidth: 440, maxWidth: 520,
               minHeight: 420, idealHeight: 560, maxHeight: 1000)
    }
}
