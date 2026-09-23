//
//  ShortcutRecorder.swift
//  Huemeleon
//
//  A small button that records a global keyboard shortcut into the store.
//

import SwiftUI
import AppKit
import Carbon.HIToolbox

struct ShortcutRecorder: NSViewRepresentable {
    let store: ColorStore

    func makeNSView(context: Context) -> RecorderButton {
        let b = RecorderButton()
        b.store = store
        b.refresh()
        return b
    }
    func updateNSView(_ nsView: RecorderButton, context: Context) { nsView.refresh() }
}

final class RecorderButton: NSButton {
    var store: ColorStore!
    private var recording = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(startRecording)
    }
    required init?(coder: NSCoder) { fatalError() }

    func refresh() { if !recording { title = store.shortcutDisplay } }

    @objc private func startRecording() {
        recording = true
        title = "Press keys…"
        window?.makeFirstResponder(self)
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard recording else { super.keyDown(with: event); return }
        if event.keyCode == 53 {                 // Esc cancels
            recording = false; refresh(); window?.makeFirstResponder(nil); return
        }
        let mods = event.modifierFlags
        var carbon: UInt32 = 0
        if mods.contains(.command) { carbon |= UInt32(cmdKey) }
        if mods.contains(.shift)   { carbon |= UInt32(shiftKey) }
        if mods.contains(.option)  { carbon |= UInt32(optionKey) }
        if mods.contains(.control) { carbon |= UInt32(controlKey) }
        guard carbon != 0 else { return }         // require a modifier

        store.setShortcut(keyCode: UInt32(event.keyCode), modifiers: carbon,
                          display: Self.display(mods, event))
        recording = false
        refresh()
        window?.makeFirstResponder(nil)
    }

    private static func display(_ mods: NSEvent.ModifierFlags, _ event: NSEvent) -> String {
        var s = ""
        if mods.contains(.control) { s += "⌃" }
        if mods.contains(.option)  { s += "⌥" }
        if mods.contains(.shift)   { s += "⇧" }
        if mods.contains(.command) { s += "⌘" }
        return s + (event.charactersIgnoringModifiers ?? "").uppercased()
    }
}
