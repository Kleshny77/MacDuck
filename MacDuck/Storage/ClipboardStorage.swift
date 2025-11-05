//
//  ClipboardStorage.swift
//  MacDuck
//
//  Created by Codex on 05.11.2025.
//

import Foundation

final class ClipboardStorage {

    private let defaults = UserDefaults.standard
    private let storageKey = "clipboard.history.v1"

    func load() -> [ClipboardItem] {
        guard let data = defaults.data(forKey: storageKey) else { return [] }
        do {
            return try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ items: [ClipboardItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: storageKey)
        } catch { }
    }
}
