//
//  PomodoroModels.swift
//  MacDuck
//
//  Created by Эльвира Матвеенко on 01.11.2025.
//

import Foundation

// Модель одной сессии Pomodoro (фокус-интервал)
struct PomodoroSession: Codable, Identifiable {
    let id: UUID
    let taskID: UUID?
    let taskTitle: String?
    let totalDuration: TimeInterval
    let startedAt: Date
    let finishedAt: Date
}

// Текущее состояние работающей сессии (в памяти)
struct RunningPomodoroState {
    let taskID: UUID?
    let taskTitle: String?
    let totalDuration: TimeInterval
    var remaining: TimeInterval
    let startedAt: Date
    var isPaused: Bool
}
