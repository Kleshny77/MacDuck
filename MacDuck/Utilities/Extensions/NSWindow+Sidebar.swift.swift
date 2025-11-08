//
//  NSWindow+Sidebar.swift.swift
//  MacDuck
//
//  Created by Эльвира Матвеенко on 01.11.2025.
//

internal import AppKit

extension NSWindow {
    @objc func toggleSidebar(_ sender: Any?) {
        let selector = #selector(NSSplitViewController.toggleSidebar(_:))
        firstResponder?.tryToPerform(selector, with: sender)
    }
}
