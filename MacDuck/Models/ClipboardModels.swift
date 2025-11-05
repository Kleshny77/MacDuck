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

    init(id: UUID = UUID(), content: String, capturedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
    }

    var preview: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmptyPreview: Bool {
        preview.isEmpty
    }
}
