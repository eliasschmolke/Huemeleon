//
//  HuemeleonApp.swift
//  Huemeleon
//
//  App-Entry. Fenster-App mit Dock-Icon (Hauptfenster) + Menüleisten-Schnellzugriff
//  + globalem Hotkey ⌘⇧C.
//

import SwiftUI
import Carbon.HIToolbox

@main
struct HuemeleonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Huemeleon", id: "main") {
            RootView()
                .environment(appDelegate.store)
                .environment(appDelegate.controller)
        }
        .windowResizability(.contentSize)

        Window("All Palettes", id: "all-palettes") {
            AllPalettesView()
                .environment(appDelegate.store)
                .environment(appDelegate.controller)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("Huemeleon", image: "MenuBarIcon") {
            MenuBarView()
                .environment(appDelegate.store)
                .environment(appDelegate.controller)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appDelegate.store)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ColorStore()
    lazy var controller = PickController(store: store)
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)   // Dock-Icon, echte Fenster-App
        store.onShortcutChange = { [weak self] in self?.registerHotKey() }
        registerHotKey()

        // Dock-Icon: bei Farbwechsel und beim Umlegen des Schalters neu färben.
        store.onTintChange = { [weak self] in self?.controller.applyDockIcon() }
        controller.applyDockIcon()   // beim Start letzte Farbe übernehmen
    }

    private func registerHotKey() {
        hotKey = HotKey(keyCode: store.shortcutKeyCode, modifiers: store.shortcutModifiers) { [weak self] in
            MainActor.assumeIsolated { self?.controller.pick() }
        }
    }
}
