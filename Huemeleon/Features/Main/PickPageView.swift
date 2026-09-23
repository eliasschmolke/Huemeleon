//
//  PickPageView.swift
//  Huemeleon
//
//  Pick page: current color block, values, recent colors (2×4), "Add to Palette",
//  and the Pick button at the bottom.
//

import SwiftUI

struct PickPageView: View {
    @Environment(ColorStore.self) private var store
    @Environment(PickController.self) private var controller

    private var focus: PickedColor { controller.current ?? PickedColor(red: 1, green: 1, blue: 1) }

    var body: some View {
        VStack(spacing: 14) {
            ScrollView {
                VStack(spacing: 16) {
                    colorBlock
                    ColorValuesView(color: controller.current)
                    recent
                }
                .padding(.bottom, 4)
            }
            .scrollIndicators(.never)

            if controller.current != nil {
                Menu {
                    Button { controller.newPaletteFromCurrent() } label: {
                        Label("New Palette", systemImage: "plus")
                    }
                    if !store.savedPalettes.isEmpty {
                        Section("Add to Existing") {
                            ForEach(store.savedPalettes) { p in
                                Button(p.name) { controller.addCurrentToPalette(p.id) }
                            }
                        }
                    }
                } label: {
                    Label("Add to Palette", systemImage: "rectangle.stack.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .menuStyle(.button)
                .controlSize(.large)
            }

            Button { controller.pick() } label: {
                Label("Pick", systemImage: "eyedropper.halffull").frame(maxWidth: .infinity)
            }
            .controlSize(.large).buttonStyle(.borderedProminent)
            .disabled(controller.isPicking)
        }
    }

    private var colorBlock: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(controller.current?.swiftUIColor ?? Color(nsColor: .quaternaryLabelColor))
            .frame(height: 110)
            .overlay {
                if controller.current == nil {
                    Text("No color").font(.callout).foregroundStyle(.secondary)
                }
            }
            .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.black.opacity(0.1)) }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECENT").font(.caption2).fontWeight(.semibold).foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(Array(store.recentColors.prefix(8))) { c in
                    Button { controller.setCurrent(c, copy: true) } label: {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(c.swiftUIColor).frame(height: 28)
                            .overlay { RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(.black.opacity(0.1)) }
                    }
                    .buttonStyle(.plain).help(c.hex)
                }
            }
        }
    }
}
