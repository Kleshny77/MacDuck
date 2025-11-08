//
//  FileCommand.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import Foundation
import AppKit

class FileCommand: LauncherCommand {
    let id: String
    let name: String
    let keywords: [String]
    let description: String
    let icon: String
    let fileURL: URL
    let appIcon: NSImage?
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        
        // Получаем имя файла
        self.name = fileURL.lastPathComponent
        self.id = fileURL.path
        
        // Ключевые слова для поиска: имя файла и его части
        var keywordSet: Set<String> = [name.lowercased()]
        let nameParts = name.lowercased().split(separator: " ")
        // Добавляем только значимые части (длиннее 3 символов)
        keywordSet.formUnion(nameParts.filter { $0.count > 3 }.map { String($0) })
        
        // Добавляем расширение файла как ключевое слово
        let fileExtension = fileURL.pathExtension.lowercased()
        if !fileExtension.isEmpty && fileExtension.count > 2 {
            keywordSet.insert(fileExtension)
        }
        
        self.keywords = Array(keywordSet)
        self.description = "Открыть файл"
        self.icon = "doc"
        
        // Загружаем иконку файла
        self.appIcon = NSWorkspace.shared.icon(forFile: fileURL.path)
    }
    
    func execute() {
        NSWorkspace.shared.open(fileURL)
    }
}

