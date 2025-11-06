//
//  FloatingTimerWindow.swift
//  MacDuck
//
//  Created by Эльвира Матвеенко on 07.11.2025.
//

import SwiftUI

struct FloatingTimerWindow: View {
    @ObservedObject var service = PomodoroService.shared

    var body: some View {
        ZStack {
            Color.blackApp.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Фокус")
                    .font(Font.custom("HSESans-SemiBold", size: 14))
                    .foregroundColor(.secondaryTextApp)

                Text(timeString(service.state?.remaining ?? 0))
                    .font(Font.custom("HSESans-Bold", size: 34))
                    .foregroundColor(.mainTextApp)

                HStack(spacing: 8) {
                    if service.isRunning() {
                        Button("Пауза") {
                            service.togglePause()
                        }
                        .applySecondaryButton()
                    } else if service.isPaused() {
                        Button("Продолжить") {
                            service.togglePause()
                        }
                        .applySecondaryButton()
                    }

                    Button("Стоп") {
                        service.stop(save: true)
                        FloatingWindowManager.shared.close()
                    }
                    .applyPrimaryButton()
                }
            }
            .padding(16)
        }
        .frame(width: 220, height: 140)
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
