//
//  ClipboardHistoryService.swift
//  MacDuck
//
//  Created by Codex on 05.11.2025.
//

import Foundation
import AppKit
import CoreGraphics
import Combine

final class ClipboardHistoryService: ObservableObject {

    static let shared = ClipboardHistoryService()

    @Published private(set) var items: [ClipboardItem]

    private let storage = ClipboardStorage()
    private var monitorTimer: Timer?
    private var lastChangeCount: Int
    private let historyLimit = 50

    private init() {
        let stored = storage.load()
        self.items = stored
        self.lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }

    deinit {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    func paste(_ item: ClipboardItem) {
        promoteOrInsert(item)
        copyToPasteboard(item.content)
        storage.save(items)
        simulatePasteCommand()
    }

    private func startMonitoring() {
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.pollPasteboard()
        }

        if let monitorTimer {
            RunLoop.main.add(monitorTimer, forMode: .common)
        }
    }

    private func pollPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }

        lastChangeCount = pasteboard.changeCount

        guard let string = pasteboard.string(forType: .string) else { return }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if items.first?.content == string {
            return
        }

        let item = ClipboardItem(content: string)
        items.insert(item, at: 0)
        if items.count > historyLimit {
            items = Array(items.prefix(historyLimit))
        }
        storage.save(items)
    }

    private func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }

    private func promoteOrInsert(_ item: ClipboardItem) {
        if let index = items.firstIndex(of: item) {
            guard index != 0 else { return }

            items.remove(at: index)
            items.insert(item, at: 0)
        } else {
            items.insert(item, at: 0)
            if items.count > historyLimit {
                items = Array(items.prefix(historyLimit))
            }
        }
    }

    private func simulatePasteCommand() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        // Отправляем искусственное нажатие ⌘V, чтобы вставить текст в текущее окно.
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        keyDown?.flags = .maskCommand

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
