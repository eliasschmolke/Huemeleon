//
//  SettingsView.swift
//  Huemeleon
//
//  Native settings window (⌘,).
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(ColorStore.self) private var store

    private enum FormatCategory: String, CaseIterable, Identifiable {
        case hex = "HEX", rgb = "RGB", rgba = "RGBA", hsl = "HSL"
        var id: String { rawValue }
    }

    var body: some View {
        Form {
            Section("Clipboard") {
                Picker("Copied format", selection: categoryBinding) {
                    ForEach(FormatCategory.allCases) { Text($0.rawValue).tag($0) }
                }
                if isHex {
                    Toggle("Copy with # prefix", isOn: hashBinding)
                }
                Toggle("Copy automatically when picking", isOn: bindingAutoCopy)
            }

            Section("Picking") {
                LabeledContent("Global shortcut") {
                    ShortcutRecorder(store: store).frame(width: 120, height: 22)
                }
                Text("Click, then press a combo with ⌘ / ⇧ / ⌥ / ⌃. Opens the loupe from anywhere.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("General") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
                Toggle("Tint Dock icon to picked color", isOn: bindingTintDock)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 400)
    }

    private var isHex: Bool {
        store.clipboardFormat == .hexHash || store.clipboardFormat == .hexPlain
    }

    private var categoryBinding: Binding<FormatCategory> {
        Binding(
            get: {
                switch store.clipboardFormat {
                case .hexHash, .hexPlain: return .hex
                case .rgb:  return .rgb
                case .rgba: return .rgba
                case .hsl:  return .hsl
                }
            },
            set: { cat in
                switch cat {
                case .hex:  if !isHex { store.clipboardFormat = .hexHash }   // Toggle-Zustand erhalten
                case .rgb:  store.clipboardFormat = .rgb
                case .rgba: store.clipboardFormat = .rgba
                case .hsl:  store.clipboardFormat = .hsl
                }
            }
        )
    }

    /// # mitkopieren (an = #RRGGBB, aus = RRGGBB).
    private var hashBinding: Binding<Bool> {
        Binding(
            get: { store.clipboardFormat == .hexHash },
            set: { store.clipboardFormat = $0 ? .hexHash : .hexPlain }
        )
    }

    private var bindingAutoCopy: Binding<Bool> {
        Binding(get: { store.autoCopy }, set: { store.autoCopy = $0 })
    }

    private var bindingTintDock: Binding<Bool> {
        Binding(get: { store.tintDockIcon }, set: { store.tintDockIcon = $0 })
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { on in
                do {
                    if on { try SMAppService.mainApp.register() }
                    else { try SMAppService.mainApp.unregister() }
                } catch { }
            }
        )
    }
}
