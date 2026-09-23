//
//  PalettePageView.swift
//  Huemeleon
//
//  Palette page: current color block + values, recent palettes (preview + arrow),
//  and "Create Palette" (open-ended picking, Esc to finish).
//

import SwiftUI

struct PalettePageView: View {
    @Environment(ColorStore.self) private var store
    @Environment(PickController.self) private var controller

    var onOpen: (Palette) -> Void
    var onShowAll: () -> Void

    private var focus: PickedColor { controller.current ?? PickedColor(red: 1, green: 1, blue: 1) }

    var body: some View {
        VStack(spacing: 14) {
            ScrollView {
                VStack(spacing: 16) {
                    colorBlock
                    ColorValuesView(color: controller.current)
                    if controller.isBuildingPalette { building } else { savedPalettes }
                }
                .padding(.bottom, 4)
            }
            .scrollIndicators(.never)

            Button { controller.buildPalette(name: "") } label: {
                Label(controller.isBuildingPalette ? "Running… (Esc to finish)" : "Create Palette",
                      systemImage: "plus.square.on.square")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large).buttonStyle(.borderedProminent)
            .disabled(controller.isBuildingPalette)
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

    private var building: some View {
        VStack(spacing: 8) {
            Text("\(controller.buildingColors.count) colors · Esc to finish")
                .font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(controller.buildingColors) { c in
                    RoundedRectangle(cornerRadius: 5).fill(c.swiftUIColor).frame(height: 22)
                }
            }
        }
    }

    @ViewBuilder private var savedPalettes: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PALETTES").font(.caption2).fontWeight(.semibold).foregroundStyle(.secondary)
                Spacer()
                if !store.savedPalettes.isEmpty {
                    Button("All Palettes") { onShowAll() }
                        .font(.caption2).buttonStyle(.plain).foregroundStyle(.tint)
                }
            }
            if store.savedPalettes.isEmpty {
                Text("No saved palettes yet.")
                    .font(.caption).foregroundStyle(.tertiary)
            } else {
                ForEach(Array(store.savedPalettes.prefix(3))) { p in
                    Button { onOpen(p) } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(p.name).font(.caption).fontWeight(.medium).foregroundStyle(.primary)
                                Spacer()
                                Text("\(p.colors.count) colors").font(.caption2).foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
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
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
