//
//  ClipboardModels.swift
//  MacDuck
//
//  Created by Codex on 05.11.2025.
//

import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let capturedAt: Date
    var hotkey: ClipboardHotkey?

    init(id: UUID = UUID(), content: String, capturedAt: Date = Date(), hotkey: ClipboardHotkey? = nil) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
        self.hotkey = hotkey
    }

    var preview: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmptyPreview: Bool {
        preview.isEmpty
    }
}

struct ClipboardHotkey: Codable, Equatable {
    let keyCode: UInt32
    let carbonModifiers: UInt32
    let display: String

    static func == (lhs: ClipboardHotkey, rhs: ClipboardHotkey) -> Bool {
        lhs.keyCode == rhs.keyCode && lhs.carbonModifiers == rhs.carbonModifiers
    }
}
