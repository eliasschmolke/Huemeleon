//
//  ReorderableColorGrid.swift
//  Huemeleon
//
//  iOS-Springboard-style reorderable color grid: press-and-hold to pick up a tile
//  (full opacity, in hand), the others reflow to make room, a dashed placeholder
//  marks the target slot, and on release the tile springs into place. No system
//  drag image (so it never appears twice). Tap copies; long-press drags.
//

import SwiftUI

struct ReorderableColorGrid: View {
    @Binding var colors: [PickedColor]
    let selectMode: Bool
    @Binding var selectedIDs: Set<UUID>
    let justCopiedID: UUID?
    let onCopy: (PickedColor) -> Void
    let onReordered: () -> Void

    // Layout (adjust here if needed)
    private let columns = 4
    private let spacing: CGFloat = 8
    private let rowSpacing: CGFloat = 12
    private let tileHeight: CGFloat = 50
    private let labelHeight: CGFloat = 14

    @State private var draggingID: UUID?
    @State private var dragLocation: CGPoint = .zero
    @State private var hoveredID: UUID?

    private var cellHeight: CGFloat { tileHeight + 4 + labelHeight }

    private var rowCount: Int { Int(ceil(Double(max(colors.count, 1)) / Double(columns))) }
    private var totalHeight: CGFloat { CGFloat(rowCount) * cellHeight + CGFloat(max(rowCount - 1, 0)) * rowSpacing }

    var body: some View {
        GeometryReader { geo in
            let cellW = (geo.size.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)

            ZStack(alignment: .topLeading) {
                if let id = draggingID, let idx = colors.firstIndex(where: { $0.id == id }) {
                    placeholder(cellW: cellW).position(swatchCenter(idx, cellW))
                }
                ForEach(Array(colors.enumerated()), id: \.element.id) { index, c in
                    let isDragging = draggingID == c.id
                    tile(c, cellW: cellW)
                        .position(isDragging ? dragLocation : center(index, cellW))
                        .scaleEffect(isDragging ? 1.08 : 1)
                        .shadow(color: .black.opacity(isDragging ? 0.28 : 0), radius: 7, y: 4)
                        .zIndex(isDragging ? 2 : 1)
                        .gesture(reorderGesture(c, index: index, cellW: cellW))
                }
            }
            .frame(width: geo.size.width, height: totalHeight, alignment: .topLeading)
            .coordinateSpace(name: "grid")
        }
        .frame(height: totalHeight)
    }

    // MARK: Tile

    private func tile(_ c: PickedColor, cellW: CGFloat) -> some View {
        let selected = selectedIDs.contains(c.id)
        let showCheck = justCopiedID == c.id
        let hovered = hoveredID == c.id && draggingID == nil
        let showIcon = !selectMode && (hovered || showCheck)
        return VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(c.swiftUIColor)
                .frame(width: cellW, height: tileHeight)
                .opacity(selectMode && !selected ? 0.5 : 1)
                .overlay {
                    if showIcon {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.black.opacity(showCheck ? 0.4 : 0.2))
                            Image(systemName: showCheck ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(showCheck ? Color.green : .white)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .transition(.opacity)
                    }
                }
                .overlay { RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.black.opacity(0.1)) }
                .overlay(alignment: .topLeading) { if selectMode { selectionCircle(selected).padding(6) } }
            Text(c.hex).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(width: cellW, height: cellHeight)
        .contentShape(Rectangle())
        .help(selectMode ? "Select color" : "Copy \(c.hex)")
        .onHover { inside in if inside { hoveredID = c.id } else if hoveredID == c.id { hoveredID = nil } }
        .onTapGesture { if selectMode { toggle(c) } else { onCopy(c) } }
        .animation(.easeInOut(duration: 0.15), value: hoveredID)
        .animation(.easeInOut(duration: 0.2), value: justCopiedID)
    }

    private func selectionCircle(_ selected: Bool) -> some View {
        Group {
            if selected {
                Image(systemName: "checkmark.circle.fill").symbolRenderingMode(.palette).foregroundStyle(.white, Color.accentColor)
            } else {
                Image(systemName: "circle").foregroundStyle(.white).shadow(color: .black.opacity(0.4), radius: 1)
            }
        }
        .font(.system(size: 18))
    }

    private func placeholder(cellW: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.gray.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.gray.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [4])))
            .frame(width: cellW, height: tileHeight)
    }

    // MARK: Geometry

    private func center(_ index: Int, _ cellW: CGFloat) -> CGPoint {
        let col = index % columns, row = index / columns
        return CGPoint(x: CGFloat(col) * (cellW + spacing) + cellW / 2,
                       y: CGFloat(row) * (cellHeight + rowSpacing) + cellHeight / 2)
    }

    private func swatchCenter(_ index: Int, _ cellW: CGFloat) -> CGPoint {
        let col = index % columns, row = index / columns
        return CGPoint(x: CGFloat(col) * (cellW + spacing) + cellW / 2,
                       y: CGFloat(row) * (cellHeight + rowSpacing) + tileHeight / 2)
    }

    // MARK: Interaction

    private func toggle(_ c: PickedColor) {
        if selectedIDs.contains(c.id) { selectedIDs.remove(c.id) } else { selectedIDs.insert(c.id) }
    }

    private func reorderGesture(_ c: PickedColor, index: Int, cellW: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .sequenced(before: DragGesture(coordinateSpace: .named("grid")))
            .onChanged { value in
                guard !selectMode else { return }
                if case .second(true, let drag?) = value {
                    if draggingID != c.id {
                        draggingID = c.id
                        dragLocation = center(index, cellW)
                    }
                    dragLocation = drag.location
                    reorder(cursor: drag.location, cellW: cellW)
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) { draggingID = nil }
                onReordered()
            }
    }

    private func reorder(cursor: CGPoint, cellW: CGFloat) {
        guard let id = draggingID, let from = colors.firstIndex(where: { $0.id == id }) else { return }
        let col = min(max(Int(cursor.x / (cellW + spacing)), 0), columns - 1)
        let row = max(Int(cursor.y / (cellHeight + rowSpacing)), 0)
        let target = min(max(row * columns + col, 0), colors.count - 1)
        if target != from {
            withAnimation(.snappy(duration: 0.28)) {
                colors.move(fromOffsets: IndexSet(integer: from), toOffset: target > from ? target + 1 : target)
            }
        }
    }
}
