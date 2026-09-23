//
//  HotKey.swift
//  Huemeleon
//
//  Dünner, dependency-freier Wrapper um Carbons RegisterEventHotKey –
//  die native API für echte systemweite Hotkeys.
//

import Carbon.HIToolbox
import Foundation

final class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: () -> Void
    private static var nextID: UInt32 = 1

    /// keyCode = Carbon Virtual Key (z. B. kVK_ANSI_C), modifiers = cmdKey | shiftKey …
    init(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let me = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
            me.action()   // Carbon-Handler läuft auf dem Main-Thread
            return noErr
        }, 1, &eventType, selfPtr, &handlerRef)

        let id = EventHotKeyID(signature: OSType(0x484B4559 /* 'HKEY' */), id: Self.nextID)
        Self.nextID += 1
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
