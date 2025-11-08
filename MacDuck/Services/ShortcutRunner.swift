//
//  ShortcutRunner.swift
//  MacDuck
//
//  Created by Эльвира Матвеенко on 04.11.2025.
//  Это единственный способ программно включать/выключать Focus в macOS.
//

import Foundation
internal import AppKit

enum ShortcutRunner {

    // Имена команд. Пользователь создаёт их вручную в Командах (Shortcuts)
    static let onName = "Pomodoro"
    static let offName = "Pomodoro Off"

    // Запуск команды по имени
    static func run(_ name: String) {
        guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://run-shortcut?name=\(encoded)") else { return }

        NSWorkspace.shared.open(url)
    }

    static func focusOn()  { run(onName) }
    static func focusOff() { run(offName) }
}
