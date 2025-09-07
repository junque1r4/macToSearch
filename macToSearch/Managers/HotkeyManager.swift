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
    private var captureHotKeyRef: EventHotKeyRef?
    private var chatHotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    @AppStorage("hotkey_enabled") var hotkeyEnabled: Bool = true
    @AppStorage("hotkey_keycode") var hotkeyKeyCode: Int = 49 // Space key
    @AppStorage("hotkey_modifiers") var hotkeyModifiers: Int = cmdKey + shiftKey
    
    @AppStorage("chat_hotkey_enabled") var chatHotkeyEnabled: Bool = true
    @AppStorage("chat_hotkey_keycode") var chatHotkeyKeyCode: Int = 31 // O key
    @AppStorage("chat_hotkey_modifiers") var chatHotkeyModifiers: Int = cmdKey + shiftKey
    
    var captureCallback: (() -> Void)?
    var openChatCallback: (() -> Void)?
    
    init() {
        setupHotkey()
    }
    
    deinit {
        unregisterHotkey()
    }
    
    func setupHotkey() {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, event, userData) -> OSStatus in
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()
                
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                manager.handleHotkey(id: hotKeyID.id)
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
        
        // Register capture hotkey (Command + Shift + Space)
        if hotkeyEnabled {
            var captureHotKeyID = EventHotKeyID(signature: OSType(0x4D544348), id: 1) // MTCH
            
            RegisterEventHotKey(
                UInt32(hotkeyKeyCode),
                UInt32(hotkeyModifiers),
                captureHotKeyID,
                GetApplicationEventTarget(),
                0,
                &captureHotKeyRef
            )
        }
        
        // Register chat hotkey (Command + Shift + O)
        if chatHotkeyEnabled {
            var chatHotKeyID = EventHotKeyID(signature: OSType(0x4D544348), id: 2) // MTCH
            
            RegisterEventHotKey(
                UInt32(chatHotkeyKeyCode),
                UInt32(chatHotkeyModifiers),
                chatHotKeyID,
                GetApplicationEventTarget(),
                0,
                &chatHotKeyRef
            )
        }
        
        isRegistered = true
    }
    
    func unregisterHotkey() {
        if let captureHotKeyRef = captureHotKeyRef {
            UnregisterEventHotKey(captureHotKeyRef)
        }
        if let chatHotKeyRef = chatHotKeyRef {
            UnregisterEventHotKey(chatHotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
        isRegistered = false
    }
    
    private func handleHotkey(id: UInt32) {
        DispatchQueue.main.async {
            switch id {
            case 1:
                // Capture hotkey (Command + Shift + Space)
                self.captureCallback?()
            case 2:
                // Chat hotkey (Command + Shift + O)
                self.openChatCallback?()
            default:
                break
            }
        }
    }
    
    func updateHotkey() {
        unregisterHotkey()
        setupHotkey()
    }
}