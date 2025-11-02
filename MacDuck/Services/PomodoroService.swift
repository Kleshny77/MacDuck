//
//  PomodoroService.swift
//  MacDuck
//
//  Created by Эльвира Матвеенко on 01.11.2025.
//

import Foundation
import Combine

final class PomodoroService: ObservableObject {

    @Published private(set) var state: RunningPomodoroState?

    private let dnd = DNDService()
    private let stats = StatsStorage()

    private var timer: AnyCancellable?

    func start(taskID: UUID?, taskTitle: String?, duration: TimeInterval) {
        // Если что-то уже идет — сначала останавливаем
        stop(save: false)

        state = RunningPomodoroState(
            taskID: taskID,
            taskTitle: taskTitle?.isEmpty == true ? nil : taskTitle,
            totalDuration: duration,
            remaining: duration,
            startedAt: Date(),
            isPaused: false
        )

        // Включаем DND
        dnd.setEnabled(true)

        // Запускаем раз в секунду
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func togglePause() {
        guard var s = state else { return }
        s.isPaused.toggle()
        state = s

        if s.isPaused {
            // При паузе просто прекращаем тикать
            timer?.cancel()
            timer = nil
        } else {
            // Возврат к тикам
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.tick()
                }
        }
    }

    // Полная остановка
    func stop(save: Bool = true) {
        timer?.cancel()
        timer = nil

        defer { state = nil }

        // Выключаем DND
        dnd.setEnabled(false)

        guard save, let s = state else { return }
        // Записываем завершенную сессию в статистику
        let finished = Date()
        let session = PomodoroSession(
            id: UUID(),
            taskID: s.taskID,
            taskTitle: s.taskTitle,
            totalDuration: s.totalDuration - max(0, s.remaining),
            startedAt: s.startedAt,
            finishedAt: finished
        )
        stats.append(session: session)
    }

    // Тик таймера
    private func tick() {
        guard var s = state, !s.isPaused else { return }
        s.remaining = max(0, s.remaining - 1)
        state = s

        if s.remaining <= 0 {
            // Автостоп и запись статистики
            stop(save: true)
        }
    }

    // MARK: – Быстрые геттеры для UI

    func secondsRemaining() -> Int {
        Int(state?.remaining ?? 0)
    }

    func totalSeconds() -> Int {
        Int(state?.totalDuration ?? 0)
    }

    func isRunning() -> Bool {
        state != nil && state?.isPaused == false
    }

    func isPaused() -> Bool {
        state?.isPaused ?? false
    }

    // Доступ к статистике
    func totalToday() -> TimeInterval { stats.totalToday() }
    func totalLast7Days() -> TimeInterval { stats.totalLast7Days() }
}
