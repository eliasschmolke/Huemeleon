//
//  PaletteDetailView.swift
//  Huemeleon
//
//  Palette detail. Two modes:
//   - existing (isNew = false): back arrow + name/rename, Update / Export / Delete.
//   - new review (isNew = true): name input field up front, no back arrow,
//     Discard / Export / Save.
//  Springboard-style reorderable grid, add color, select-to-delete, and the last
//  clicked color detailed at the bottom.
//

import SwiftUI

struct PaletteDetailView: View {
    @Environment(ColorStore.self) private var store

    let palette: Palette
    let onBack: () -> Void
    var isNew: Bool = false

    @State private var name = ""
    @State private var colors: [PickedColor] = []
    @State private var selectMode = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var isRenaming = false
    @FocusState private var nameFocused: Bool

    @State private var lastClicked: PickedColor?
    @State private var justCopied: UUID?
    @State private var copyToken = 0
    @State private var showColorInput = false
    @State private var didSave = false
    private enum PickingMode { case none, single, multiple }
    @State private var pickingMode: PickingMode = .none
    @State private var pickBaseline = 0

    init(palette: Palette, isNew: Bool = false, onBack: @escaping () -> Void) {
        self.palette = palette
        self.isNew = isNew
        self.onBack = onBack
        _name = State(initialValue: isNew ? "" : palette.name)
        _colors = State(initialValue: palette.colors)
        _lastClicked = State(initialValue: palette.colors.first)
    }

    private var edited: Palette {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let finalName = trimmed.isEmpty ? (isNew ? defaultName() : "Palette") : trimmed
        return Palette(id: palette.id, name: finalName, colors: colors, createdAt: palette.createdAt)
    }

    /// Nächster freier "Palette N"-Name.
    private func defaultName() -> String {
        let existing = Set(store.savedPalettes.map { $0.name })
        var n = 1
        while existing.contains("Palette \(n)") { n += 1 }
        return "Palette \(n)"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 0) {
                ScrollView {
                    ReorderableColorGrid(
                        colors: $colors,
                        selectMode: selectMode,
                        selectedIDs: $selectedIDs,
                        justCopiedID: justCopied,
                        onCopy: { copyColor($0) },
                        onReordered: { persistIfSaved() }
                    )
                    .padding(16)
                    .thinScrollBars()
                }
                if !selectMode, let lc = lastClicked {
                    Divider()
                    lastClickedPanel(lc)
                }
                Divider()
                footer
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { nameFocused = false })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { if isNew { nameFocused = true } }
        .onChange(of: nameFocused) { _, focused in
            if !focused && isRenaming { finishRename() }   // Klick woanders / Tab -> Namen übernehmen
        }
        .sheet(isPresented: $showColorInput) {
            ColorInputView(onAdd: { c in
                withAnimation(.snappy) { colors.append(c) }
                lastClicked = c
                persistIfSaved()
                showColorInput = false
            }, onCancel: { showColorInput = false })
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            if isNew {
                TextField("Palette name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
                    .focused($nameFocused)
                    .frame(maxWidth: .infinity)
                    .onSubmit { saveNew() }
            } else {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain).help("Back")

                if isRenaming {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.headline)
                        .focused($nameFocused)
                        .frame(maxWidth: .infinity)
                        .onSubmit { finishRename() }
                } else {
                    Text(name.isEmpty ? "Palette" : name)
                        .font(.title3).fontWeight(.semibold).lineLimit(1)
                    Spacer()
                }
            }

            // Während des Umbenennens nur den Bestätigen-Haken zeigen.
            if !selectMode && !isRenaming {
                addMenu
            }
            if !isNew && !selectMode {
                Button {
                    if isRenaming { finishRename() } else { isRenaming = true; nameFocused = true }
                } label: {
                    Image(systemName: isRenaming ? "checkmark" : "pencil")
                        .frame(width: 22, height: 22).contentShape(Rectangle())
                }
                .buttonStyle(.plain).help(isRenaming ? "Done" : "Rename")
            }
            if !isRenaming {
                Button(selectMode ? "Done" : "Select") {
                    selectMode.toggle()
                    if !selectMode { selectedIDs.removeAll() }
                }
                .buttonStyle(.plain).foregroundStyle(.tint)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
    }

    private var addMenu: some View {
        Menu {
            Menu {
                Button { pickAndAdd() } label: { Label("Pick single", systemImage: "eyedropper") }
                Button { pickMultipleAndAdd() } label: { Label("Pick multiple", systemImage: "eyedropper.halffull") }
            } label: {
                Label("Pick", systemImage: "eyedropper")
            }
            Button { showColorInput = true } label: { Label("Enter manually", systemImage: "square.and.pencil") }
        } label: {
            Image(systemName: "plus")
        }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        .help("Add color")
    }

    // MARK: Last clicked color

    private func lastClickedPanel(_ lc: PickedColor) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(lc.swiftUIColor).frame(width: 50, height: 50)
                .overlay { RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.black.opacity(0.1)) }
            ColorValuesView(color: lc)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: Footer

    @ViewBuilder private var footer: some View {
        if pickingMode != .none {
            HStack(spacing: 6) {
                Image(systemName: "eyedropper.halffull").foregroundStyle(.tint)
                Text(pickingMode == .multiple ? "Picking colors…" : "Picking color…")
                    .font(.callout).fontWeight(.medium)
                if pickingMode == .multiple {
                    Text("\(max(colors.count - pickBaseline, 0))")
                        .font(.callout).fontWeight(.semibold).foregroundStyle(.secondary)
                }
                Spacer()
                Text(pickingMode == .multiple ? "Esc to finish" : "Esc to cancel")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .padding(12)
        } else if selectMode {
            HStack {
                Text("\(selectedIDs.count) selected").font(.callout).foregroundStyle(.secondary)
                Spacer()
                Button(role: .destructive) { deleteSelected() } label: { Label("Delete", systemImage: "trash") }
                    .disabled(selectedIDs.isEmpty)
            }
            .padding(12)
        } else if isNew {
            HStack(spacing: 10) {
                Button("Discard", role: .destructive) { onBack() }
                Spacer()
                exportMenu
                Button { saveNew() } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        } else {
            HStack(spacing: 10) {
                Button { store.savePalette(edited) } label: {
                    Label(store.isSaved(palette) ? "Update" : "Save", systemImage: "square.and.arrow.down")
                }
                exportMenu
                Spacer()
                if store.isSaved(palette) {
                    Button(role: .destructive) { store.deletePalette(palette); onBack() } label: {
                        Image(systemName: "trash")
                    }
                    .help("Delete entire palette")
                }
            }
            .padding(12)
        }
    }

    private var exportMenu: some View {
        Menu {
            ForEach(PaletteExportFormat.allCases) { fmt in
                Button(fmt.displayName) { ExportService.save(edited, as: fmt) }
            }
        } label: { Label("Export", systemImage: "square.and.arrow.up") }
        .fixedSize()
    }

    // MARK: Actions

    private func pickAndAdd() {
        Task {
            withAnimation { pickingMode = .single }
            if let picked = await SystemColorSampler().pickOnce() {
                withAnimation(.snappy) { colors.append(picked) }
                lastClicked = picked
            }
            withAnimation { pickingMode = .none }
            persistIfSaved()
        }
    }

    private func pickMultipleAndAdd() {
        Task {
            pickBaseline = colors.count
            withAnimation { pickingMode = .multiple }
            var first = true
            while true {
                if !first { try? await Task.sleep(nanoseconds: 180_000_000) }
                first = false
                guard let picked = await SystemColorSampler().pickOnce() else { break }   // Esc beendet
                withAnimation(.snappy) { colors.append(picked) }
                lastClicked = picked
            }
            withAnimation { pickingMode = .none }
            persistIfSaved()
        }
    }

    private func saveNew() {
        guard !didSave else { return }
        didSave = true
        store.savePalette(edited)
        onBack()
    }

    private func copyColor(_ c: PickedColor) {
        store.recopy(c)
        lastClicked = c
        withAnimation(.easeInOut(duration: 0.2)) { justCopied = c.id }
        copyToken += 1
        let t = copyToken
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if copyToken == t { withAnimation(.easeInOut(duration: 0.2)) { justCopied = nil } }
        }
    }

    private func deleteSelected() {
        withAnimation(.snappy) { colors.removeAll { selectedIDs.contains($0.id) } }
        if let lc = lastClicked, !colors.contains(where: { $0.id == lc.id }) { lastClicked = colors.first }
        selectedIDs.removeAll()
        persistIfSaved()
    }

    private func finishRename() {
        isRenaming = false
        nameFocused = false
        persistIfSaved()
    }

    private func persistIfSaved() {
        if !isNew, store.isSaved(palette) { store.savePalette(edited) }
    }
}
