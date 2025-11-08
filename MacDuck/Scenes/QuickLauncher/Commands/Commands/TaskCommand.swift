//
//  TaskCommand.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import Foundation
import AppKit

class TaskCommand: LauncherCommand {
    let id = "task"
    let name = "task"
    let keywords = ["задача", "task", "добавить", "add"]
    let description = "Добавить новую задачу"
    let icon = "checklist"
    let appIcon: NSImage? = nil
    
    func execute() {
        // TODO: Реализовать открытие окна создания задачи
        print("Executing task command")
    }
}

