//
//  DNDService.swift
//  MacDuck
//
//  Created by Эльвира Матвеенко on 01.11.2025.
//

import Foundation
import AppKit

final class DNDService {

    func setEnabled(_ enabled: Bool) {
        let script = enabled
        ? """
           do shell script "defaults -currentHost write com.apple.notificationcenterui doNotDisturb -bool true && killall NotificationCenter"
           """
        : """
           do shell script "defaults -currentHost write com.apple.notificationcenterui doNotDisturb -bool false && killall NotificationCenter"
           """
        
        var errorDict: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            _ = appleScript.executeAndReturnError(&errorDict)
            if let error = errorDict { print("DND AppleScript error: \(error)") }
        }
    }
}
