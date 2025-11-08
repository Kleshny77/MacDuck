//
//  GlobalHotKeyService.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import AppKit
import Carbon

class GlobalHotKeyService {
    static let shared = GlobalHotKeyService()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var hotKeyID: EventHotKeyID = {
        var signature: FourCharCode = 0
        "MDHK".utf8.enumerated().forEach { index, byte in
            signature |= FourCharCode(byte) << (8 * (3 - index))
        }
        return EventHotKeyID(signature: signature, id: 1)
    }()
    private var hotKeyCallback: (() -> Void)?
    private var isEnabled: Bool = false
    
    var isRegistered: Bool {
        return isEnabled && hotKeyRef != nil
    }
    
    private init() {}
    
    func registerHotKey(keyCode: UInt32 = 49, modifiers: UInt32 = 3, callback: @escaping () -> Void) {
        unregisterHotKey()
        
        self.hotKeyCallback = callback
        self.isEnabled = true
        
        var eventTypes = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))]
        
        let eventHandlerCallback: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                theEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr {
                let service = Unmanaged<GlobalHotKeyService>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    service.hotKeyCallback?()
                }
            }
            
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            eventHandlerCallback,
            1,
            &eventTypes,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            self.hotKeyRef = hotKeyRef
        }
    }
    
    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        self.isEnabled = false
        hotKeyCallback = nil
    }
    
    deinit {
        unregisterHotKey()
    }
}
