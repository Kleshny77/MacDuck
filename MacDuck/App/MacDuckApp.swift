//
//  MacDuckApp.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import SwiftUI
import AppKit
import Carbon

@main
struct MacDuckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.dark)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibilityPermissions()
        _ = CommandRegistry.shared
        registerHotKey()
    }
    
    private func checkAccessibilityPermissions() {
        let accessibilityEnabled = AXIsProcessTrusted()
        
        if !accessibilityEnabled {
            let hasSeenPrompt = UserDefaults.standard.bool(forKey: "hasSeenAccessibilityPrompt")
            
            if !hasSeenPrompt {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let alert = NSAlert()
                    alert.messageText = "Требуются разрешения Accessibility"
                    alert.informativeText = "MacDuck нуждается в разрешениях Accessibility для работы глобальных горячих клавиш. Пожалуйста, разрешите доступ в Системных настройках."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Открыть Настройки")
                    alert.addButton(withTitle: "Позже")
                    
                    let response = alert.runModal()
                    
                    UserDefaults.standard.set(true, forKey: "hasSeenAccessibilityPrompt")
                    
                    if response == .alertFirstButtonReturn {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        GlobalHotKeyService.shared.unregisterHotKey()
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        if QuickLauncherWindow.shared.isVisible {
            QuickLauncherWindow.shared.hide()
        }
    }
    
    func applicationWillHide(_ notification: Notification) {
        if QuickLauncherWindow.shared.isVisible {
            QuickLauncherWindow.shared.hide()
        }
    }
    
    private func registerHotKey() {
        let keyCode = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? UInt32 ?? 49
        let modifiers = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt32 ?? 3
        
        GlobalHotKeyService.shared.registerHotKey(
            keyCode: keyCode,
            modifiers: modifiers,
            callback: {
                QuickLauncherWindow.shared.toggle()
            }
        )
    }
}
