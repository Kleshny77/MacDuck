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
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Инициализируем CommandRegistry для загрузки команд (это загрузит приложения)
        _ = CommandRegistry.shared
        
        // Регистрируем локальную горячую клавишу
        // Горячая клавиша будет работать только когда приложение активно
        registerHotKey()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        GlobalHotKeyService.shared.unregisterHotKey()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Приложение стало активным - глобальный хоткей уже работает, ничего не делаем
        // Локальный монитор будет работать автоматически
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        // Приложение потеряло фокус - скрываем лаунчер, но оставляем глобальный хоткей активным
        if QuickLauncherWindow.shared.isVisible {
            QuickLauncherWindow.shared.hide()
        }
    }
    
    func applicationWillHide(_ notification: Notification) {
        // Приложение скрыто - скрываем лаунчер, но оставляем глобальный хоткей активным
        if QuickLauncherWindow.shared.isVisible {
            QuickLauncherWindow.shared.hide()
        }
    }
    
    private func registerHotKey() {
        // Загружаем сохраненные настройки или используем значения по умолчанию
        let keyCode = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? UInt32 ?? 49 // Space по умолчанию
        let modifiers = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt32 ?? 3 // Cmd по умолчанию
        
        GlobalHotKeyService.shared.registerHotKey(
            keyCode: keyCode,
            modifiers: modifiers,
            callback: {
                QuickLauncherWindow.shared.toggle()
            }
        )
    }
}
