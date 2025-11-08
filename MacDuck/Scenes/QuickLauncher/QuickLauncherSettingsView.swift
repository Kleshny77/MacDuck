//
//  QuickLauncherSettingsView.swift
//  MacDuck
//
//  Created by Artem Samsonov on 06.11.2025.
//

import SwiftUI
import AppKit

struct QuickLauncherSettingsView: View {
    @State private var hotkeyEnabled: Bool = true
    @State private var hotkeyKeyCode: UInt32 = 49 // Space
    @State private var hotkeyModifiers: UInt32 = 3 // Cmd
    @State private var isRecording: Bool = false
    @State private var recordingKeyCode: UInt16? = nil
    @State private var recordingModifiers: NSEvent.ModifierFlags = []
    @State private var recordingMonitor: Any? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Настройки быстрого лаунчера")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.mainTextApp)
            
            Divider()
                .background(Color.borderApp)
            
            // Настройка горячей клавиши
            VStack(alignment: .leading, spacing: 12) {
                Text("Горячая клавиша")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.mainTextApp)
                
                Toggle("Включить быстрый лаунчер", isOn: $hotkeyEnabled)
                    .font(.system(size: 15))
                    .foregroundColor(.mainTextApp)
                    .onChange(of: hotkeyEnabled) { newValue in
                        if newValue {
                            registerHotkey()
                        } else {
                            unregisterHotkey()
                        }
                    }
                
                if hotkeyEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text("Текущая комбинация:")
                                .font(.system(size: 14))
                                .foregroundColor(.secondaryTextApp)
                            
                            Button(action: {
                                startRecording()
                            }) {
                                HStack(spacing: 4) {
                                    if isRecording {
                                        Image(systemName: "record.circle.fill")
                                            .foregroundColor(.redAccent)
                                            .font(.system(size: 10))
                                        Text(recordingKeyCode != nil ? formatKeyCombo(keyCode: recordingKeyCode!, modifiers: recordingModifiers) : "Нажмите комбинацию...")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.mainTextApp)
                                    } else {
                                        Text(formatKeyCombo(keyCode: UInt16(hotkeyKeyCode), modifiers: convertModifiers(hotkeyModifiers)))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.mainTextApp)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isRecording ? Color.redAccent.opacity(0.2) : Color.lightGrayApp)
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            
                            if isRecording {
                                Button("Отмена") {
                                    cancelRecording()
                                }
                                .font(.system(size: 12))
                                .foregroundColor(.secondaryTextApp)
                            }
                        }
                        
                        if isRecording {
                            Text("Нажмите новую комбинацию клавиш, затем Enter для сохранения")
                                .font(.system(size: 12))
                                .foregroundColor(.orangeAccent)
                        }
                    }
                    .padding(.leading, 20)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        .onAppear {
            // Проверяем, зарегистрирована ли горячая клавиша
            hotkeyEnabled = GlobalHotKeyService.shared.isRegistered
            // Загружаем сохраненные настройки
            loadHotkeySettings()
        }
        .onDisappear {
            // Отменяем запись при закрытии
            if isRecording {
                cancelRecording()
            }
        }
    }
    
    private func loadHotkeySettings() {
        // Загружаем из UserDefaults
        if let savedKeyCode = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? UInt32 {
            hotkeyKeyCode = savedKeyCode
        }
        if let savedModifiers = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt32 {
            hotkeyModifiers = savedModifiers
        }
    }
    
    private func saveHotkeySettings() {
        // Сохраняем в UserDefaults
        UserDefaults.standard.set(hotkeyKeyCode, forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(hotkeyModifiers, forKey: "hotkeyModifiers")
    }
    
    private func startRecording() {
        isRecording = true
        recordingKeyCode = nil
        recordingModifiers = []
        
        // Отменяем текущую горячую клавишу временно
        if hotkeyEnabled {
            GlobalHotKeyService.shared.unregisterHotKey()
        }
        
        // Создаем монитор для записи новой комбинации
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard self.isRecording else { return event }
            
            // Если нажата Enter - сохраняем комбинацию
            if event.keyCode == 36 && event.type == .keyDown { // Enter key
                if let keyCode = recordingKeyCode {
                    // Сохраняем новую комбинацию
                    hotkeyKeyCode = UInt32(keyCode)
                    hotkeyModifiers = convertModifiersToCarbon(recordingModifiers)
                    saveHotkeySettings()
                    
                    // Регистрируем новую горячую клавишу
                    if hotkeyEnabled {
                        registerHotkey()
                    }
                    
                    // Завершаем запись
                    cancelRecording()
                    return nil // Поглощаем Enter
                }
            }
            
            // Если нажата Escape - отменяем запись
            if event.keyCode == 53 && event.type == .keyDown { // Escape key
                cancelRecording()
                return nil // Поглощаем Escape
            }
            
            // Записываем комбинацию клавиш
            if event.type == .keyDown {
                let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
                
                // Игнорируем если нет модификаторов или нет основной клавиши
                if !modifiers.isEmpty && event.keyCode != 0 {
                    recordingKeyCode = event.keyCode
                    recordingModifiers = modifiers
                }
            }
            
            return event
        }
    }
    
    private func cancelRecording() {
        isRecording = false
        recordingKeyCode = nil
        recordingModifiers = []
        
        // Удаляем монитор записи
        if let monitor = recordingMonitor {
            NSEvent.removeMonitor(monitor)
            recordingMonitor = nil
        }
        
        // Восстанавливаем горячую клавишу если она была включена
        if hotkeyEnabled {
            registerHotkey()
        }
    }
    
    private func registerHotkey() {
        GlobalHotKeyService.shared.registerHotKey(
            keyCode: hotkeyKeyCode,
            modifiers: hotkeyModifiers,
            callback: {
                QuickLauncherWindow.shared.toggle()
            }
        )
    }
    
    private func unregisterHotkey() {
        GlobalHotKeyService.shared.unregisterHotKey()
    }
    
    private func formatKeyCombo(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        
        if modifiers.contains(.command) {
            parts.append("⌘")
        }
        if modifiers.contains(.control) {
            parts.append("⌃")
        }
        if modifiers.contains(.option) {
            parts.append("⌥")
        }
        if modifiers.contains(.shift) {
            parts.append("⇧")
        }
        
        // Получаем название клавиши
        let keyName = getKeyName(keyCode: keyCode)
        parts.append(keyName)
        
        return parts.joined(separator: " ")
    }
    
    private func getKeyName(keyCode: UInt16) -> String {
        // Маппинг кодов клавиш на названия
        let keyNames: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 31: "O", 32: "U",
            34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
            49: "Space", 36: "Enter", 48: "Tab", 51: "Delete", 53: "Escape",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
            101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        
        return keyNames[keyCode] ?? "Key \(keyCode)"
    }
    
    private func convertModifiers(_ carbonModifiers: UInt32) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        
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
    
    private func convertModifiersToCarbon(_ modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        
        if modifiers.contains(.command) {
            carbon |= 0x0100
        }
        if modifiers.contains(.control) {
            carbon |= 0x1000
        }
        if modifiers.contains(.option) {
            carbon |= 0x0800
        }
        if modifiers.contains(.shift) {
            carbon |= 0x0200
        }
        
        return carbon
    }
}


