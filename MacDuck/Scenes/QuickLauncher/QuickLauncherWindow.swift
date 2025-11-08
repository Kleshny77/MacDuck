//
//  QuickLauncherWindow.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import AppKit
import SwiftUI

class QuickLauncherWindow: NSWindow {
    static let shared = QuickLauncherWindow()
    
    private init() {
        let screenRect = NSScreen.main?.frame ?? .zero
        let windowSize = NSSize(width: 580, height: 360)
        let windowRect = NSRect(
            x: screenRect.midX - windowSize.width / 2,
            y: screenRect.midY + 100,
            width: windowSize.width,
            height: windowSize.height
        )
        
        super.init(
            contentRect: windowRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        ignoresMouseEvents = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        acceptsMouseMovedEvents = true
        minSize = NSSize(width: 400, height: 300)
        maxSize = NSSize(width: 1000, height: 800)
        
        let hostingView = NSHostingView(rootView: QuickLauncherView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 10
        hostingView.layer?.masksToBounds = true
        contentView = hostingView
        
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: contentView!.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor)
        ])
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    func show() {
        let newView = QuickLauncherView()
        let newHostingView = NSHostingView(rootView: newView)
        newHostingView.translatesAutoresizingMaskIntoConstraints = false
        newHostingView.wantsLayer = true
        newHostingView.layer?.cornerRadius = 10
        newHostingView.layer?.masksToBounds = true
        contentView = newHostingView
        
        NSLayoutConstraint.activate([
            newHostingView.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor),
            newHostingView.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor),
            newHostingView.topAnchor.constraint(equalTo: contentView!.topAnchor),
            newHostingView.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor)
        ])
        
        alphaValue = 0.0
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.makeKey()
            self.makeFirstResponder(nil)
        }
    }
    
    func hide() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            self.alphaValue = 1.0
        })
    }
    
    func toggle() {
        isVisible ? hide() : show()
    }
}
