//
//  GlobalHotKeyService.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import AppKit
import Carbon
import CoreGraphics

class GlobalHotKeyService {
    static let shared = GlobalHotKeyService()
    
    private var localMonitor: Any?
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var eventTap: CFMachPort?
    private var hotKeyID: EventHotKeyID = {
        var signature: FourCharCode = 0
        "MDHK".utf8.enumerated().forEach { index, byte in
            signature |= FourCharCode(byte) << (8 * (3 - index))
        }
        return EventHotKeyID(signature: signature, id: 1)
    }()
    private var hotKeyCallback: (() -> Void)?
    private var keyCode: UInt16 = 49 // Space
    private var modifiers: NSEvent.ModifierFlags = [.command]
    private var carbonModifiers: UInt32 = 0
    private var isEnabled: Bool = false
    
    var isRegistered: Bool {
        return isEnabled && (localMonitor != nil || hotKeyRef != nil)
    }
    
    private init() {
        // Обработчик событий будет установлен при регистрации хоткея
    }
    
    func registerHotKey(keyCode: UInt32 = 49, // Space key
                       modifiers: UInt32 = UInt32(3), // Cmd
                       callback: @escaping () -> Void) {
        // Remove existing hotkey if any
        unregisterHotKey()
        
        self.keyCode = UInt16(keyCode)
        self.modifiers = convertModifiers(modifiers)
        self.carbonModifiers = modifiers
        self.hotKeyCallback = callback
        self.isEnabled = true
        
        // Локальный монитор - работает когда приложение активно
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self, self.isEnabled else { return event }
            
            // Проверяем комбинацию клавиш
            if event.keyCode == self.keyCode {
                // Проверяем, что нажаты только нужные модификаторы
                let pressedModifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
                if pressedModifiers == self.modifiers {
                    self.hotKeyCallback?()
                    return nil // Поглощаем событие
                }
            }
            
            return event
        }
        
        // Используем CGEventTap для глобального хоткея (работает из всех приложений)
        setupGlobalEventTap()
        
        // Также используем Carbon API для глобального хоткея
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(carbonModifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            self.hotKeyRef = hotKeyRef
            print("Global hotkey registered successfully via Carbon API: keyCode=\(keyCode), modifiers=\(carbonModifiers)")
        } else {
            print("Failed to register global hotkey via Carbon API: status=\(status), keyCode=\(keyCode), modifiers=\(carbonModifiers)")
        }
    }
    
    private func setupGlobalEventTap() {
        // Используем CGEventTap для глобального хоткея
        // Используем .cgAnnotatedSessionEventTap для работы из всех приложений
        let eventsOfInterest: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<GlobalHotKeyService>.fromOpaque(refcon).takeUnretainedValue()
            
            guard service.isEnabled else { return Unmanaged.passUnretained(event) }
            
            // Проверяем комбинацию клавиш
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if keyCode == Int64(service.keyCode) {
                let flags = event.flags
                let pressedModifiers = NSEvent.ModifierFlags(rawValue: UInt(flags.rawValue))
                let requiredModifiers = pressedModifiers.intersection([.command, .control, .option, .shift])
                
                if requiredModifiers == service.modifiers {
                    print("Global hotkey pressed via CGEventTap! keyCode=\(keyCode), modifiers=\(requiredModifiers)")
                    DispatchQueue.main.async {
                        service.hotKeyCallback?()
                    }
                    return nil // Поглощаем событие
                }
            }
            
            return Unmanaged.passUnretained(event)
        }
        
        // Используем .cgAnnotatedSessionEventTap для работы из всех приложений
        eventTap = CGEvent.tapCreate(
            tap: .cgAnnotatedSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventsOfInterest,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            print("CGEventTap set up successfully for global hotkey")
        } else {
            print("Failed to create CGEventTap - may need Accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility")
        }
    }
    
    func unregisterHotKey() {
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        self.isEnabled = false
        hotKeyCallback = nil
    }
    
    private func convertModifiers(_ carbonModifiers: UInt32) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        
        // Carbon modifiers: cmdKey = 0x0100, shiftKey = 0x0200, optionKey = 0x0800, controlKey = 0x1000
        if carbonModifiers & 0x0100 != 0 {
            flags.insert(.command)
        }
        if carbonModifiers & 0x1000 != 0 {
            flags.insert(.control)
        }
        if carbonModifiers & 0x0800 != 0 {
            flags.insert(.option)
        }
        if carbonModifiers & 0x0200 != 0 {
            flags.insert(.shift)
        }
        
        return flags
    }
    
    deinit {
        unregisterHotKey()
    }
}

