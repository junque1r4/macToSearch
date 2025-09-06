//
//  HotkeyManager.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import Foundation
import SwiftUI
import Carbon

class HotkeyManager: ObservableObject {
    @Published var isRegistered = false
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    @AppStorage("hotkey_enabled") var hotkeyEnabled: Bool = true
    @AppStorage("hotkey_keycode") var hotkeyKeyCode: Int = 49 // Space key
    @AppStorage("hotkey_modifiers") var hotkeyModifiers: Int = cmdKey + shiftKey
    
    var captureCallback: (() -> Void)?
    
    init() {
        setupHotkey()
    }
    
    deinit {
        unregisterHotkey()
    }
    
    func setupHotkey() {
        guard hotkeyEnabled else { return }
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, event, userData) -> OSStatus in
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()
                manager.handleHotkey()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
        
        var hotKeyID = EventHotKeyID(signature: OSType(0x4D544348), id: 1) // MTCH
        
        RegisterEventHotKey(
            UInt32(hotkeyKeyCode),
            UInt32(hotkeyModifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        isRegistered = true
    }
    
    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
        isRegistered = false
    }
    
    private func handleHotkey() {
        DispatchQueue.main.async {
            self.captureCallback?()
        }
    }
    
    func updateHotkey() {
        unregisterHotkey()
        setupHotkey()
    }
}