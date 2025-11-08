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
    @State private var hotkeyKeyCode: UInt32 = 49
    @State private var hotkeyModifiers: UInt32 = 3
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
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Горячая клавиша")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.mainTextApp)
                
                Toggle("Включить быстрый лаунчер", isOn: $hotkeyEnabled)
                    .font(.system(size: 15))
                    .foregroundColor(.mainTextApp)
                    .onChange(of: hotkeyEnabled) { newValue in
                        newValue ? registerHotkey() : unregisterHotkey()
                    }
                
                if hotkeyEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text("Текущая комбинация:")
                                .font(.system(size: 14))
                                .foregroundColor(.secondaryTextApp)
                            
                            Button(action: { startRecording() }) {
                                HStack(spacing: 4) {
                                    if isRecording {
                                        Image(systemName: "record.circle.fill")
                                            .foregroundColor(.redAccent)
                                            .font(.system(size: 10))
                                        Text(recordingKeyCode != nil ? KeyboardModifiers.formatKeyCombo(keyCode: recordingKeyCode!, modifiers: recordingModifiers) : "Нажмите комбинацию...")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.mainTextApp)
                                    } else {
                                        Text(KeyboardModifiers.formatKeyCombo(keyCode: UInt16(hotkeyKeyCode), modifiers: KeyboardModifiers.toNSEventModifiers(hotkeyModifiers)))
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
                                Button("Отмена") { cancelRecording() }
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
            hotkeyEnabled = GlobalHotKeyService.shared.isRegistered
            loadHotkeySettings()
        }
        .onDisappear {
            if isRecording { cancelRecording() }
        }
    }
    
    private func loadHotkeySettings() {
        if let savedKeyCode = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? UInt32 {
            hotkeyKeyCode = savedKeyCode
        }
        if let savedModifiers = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt32 {
            hotkeyModifiers = savedModifiers
        }
    }
    
    private func saveHotkeySettings() {
        UserDefaults.standard.set(hotkeyKeyCode, forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(hotkeyModifiers, forKey: "hotkeyModifiers")
    }
    
    private func startRecording() {
        isRecording = true
        recordingKeyCode = nil
        recordingModifiers = []
        
        if hotkeyEnabled {
            GlobalHotKeyService.shared.unregisterHotKey()
        }
        
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard self.isRecording else { return event }
            
            if event.keyCode == 36 && event.type == .keyDown {
                if let keyCode = recordingKeyCode {
                    hotkeyKeyCode = UInt32(keyCode)
                    hotkeyModifiers = KeyboardModifiers.toCarbonModifiers(recordingModifiers)
                    saveHotkeySettings()
                    
                    if hotkeyEnabled {
                        registerHotkey()
                    }
                    
                    cancelRecording()
                    return nil
                }
            }
            
            if event.keyCode == 53 && event.type == .keyDown {
                cancelRecording()
                return nil
            }
            
            if event.type == .keyDown {
                let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
                
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
        
        if let monitor = recordingMonitor {
            NSEvent.removeMonitor(monitor)
            recordingMonitor = nil
        }
        
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
}
