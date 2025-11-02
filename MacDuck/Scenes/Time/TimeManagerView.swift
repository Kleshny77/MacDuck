//
//  TimeManagerView.swift
//  MacDuck
//
//  Created by Эльвира Матвеенко on 01.11.2025.
//

import SwiftUI

struct TimeManagerView: View {

    @StateObject private var service = PomodoroService()

    @State private var taskTitle: String = ""
    @State private var selectedMinutes: Int = 25

    @State private var showCustomTimeSheet = false
    @State private var customMinutesInput: String = ""

    private let presets = [15, 25, 45]

    var body: some View {
        VStack(spacing: 16) {
            headerSection()

            timerSection()
                .padding()
                .background(Color.lightGrayApp)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            controlsSection()

            statsSection()
        }
        .padding(20)
        .background(Color.blackApp)
        .navigationTitle(Tab.timeManager.rawValue)
        .sheet(isPresented: $showCustomTimeSheet) {
            customTimeInputSheet()
        }
    }

    // MARK: UI
    
    private func headerSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Фокус-задача")
                .font(Font.custom("HSESans-SemiBold", size: 14))
                .foregroundColor(.secondaryTextApp)

            TextField("Название задачи", text: $taskTitle)
                .textFieldStyle(.roundedBorder)
                .font(Font.custom("HSESans-Regular", size: 14))

            Text("Длительность")
                .font(Font.custom("HSESans-SemiBold", size: 14))
                .foregroundColor(.secondaryTextApp)

            customSegmentControl()
        }
    }

    private func customSegmentControl() -> some View {
        HStack(spacing: 0) {
            ForEach(presets, id: \.self) { m in
                segmentButton(label: "\(m) мин", isSelected: selectedMinutes == m) {
                    selectedMinutes = m
                }
            }

            segmentButton(label: "Свое", isSelected: !presets.contains(selectedMinutes)) {
                showCustomTimeSheet.toggle()
            }
        }
        .frame(height: 32)
        .background(Color.lightGrayApp)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func segmentButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Font.custom("HSESans-Regular", size: 12))
                .foregroundColor(isSelected ? .white : .secondaryTextApp)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isSelected ? Color.grayApp : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func timerSection() -> some View {
        VStack(spacing: 8) {
            Text(formattedRemaining())
                .font(Font.custom("HSESans-Bold", size: 48))
                .foregroundColor(.mainTextApp)

            if service.isPaused() {
                Text("Пауза")
                    .font(Font.custom("HSESans-SemiBold", size: 14))
                    .foregroundColor(.secondaryTextApp)
            } else if service.isRunning() {
                Text("В фокусе…")
                    .font(Font.custom("HSESans-SemiBold", size: 14))
                    .foregroundColor(.secondaryTextApp)
            } else {
                Text("Готов к старту")
                    .font(Font.custom("HSESans-SemiBold", size: 14))
                    .foregroundColor(.secondaryTextApp)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func controlsSection() -> some View {
        HStack(spacing: 12) {
            if service.isRunning() || service.isPaused() {
                Button(service.isPaused() ? "Продолжить" : "Пауза") {
                    service.togglePause()
                }
                .applyPrimaryButton()

                Button("Стоп") {
                    service.stop()
                }
                .applySecondaryButton()

            } else {
                Button("Старт") {
                    startTimer()
                }
                .applyPrimaryButton()
            }

            Spacer()
        }
    }

    private func statsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Статистика")
                .font(Font.custom("HSESans-SemiBold", size: 14))
                .foregroundColor(.secondaryTextApp)

            HStack(spacing: 24) {
                statTile(title: "Сегодня", seconds: service.totalToday())
                statTile(title: "7 дней", seconds: service.totalLast7Days())
            }
        }
        .padding(.top, 12)
    }

    private func statTile(title: String, seconds: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Font.custom("HSESans-Regular", size: 12))
                .foregroundColor(.secondaryTextApp)
            Text(formatHHMM(from: seconds))
                .font(Font.custom("HSESans-Bold", size: 20))
                .foregroundColor(.mainTextApp)
        }
        .padding(12)
        .frame(width: 150, alignment: .leading)
        .background(Color.lightGrayApp)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Custom Time Sheet

    private func customTimeInputSheet() -> some View {
        VStack(spacing: 16) {
            Text("Выберите длительность")
                .font(Font.custom("HSESans-SemiBold", size: 16))
                .foregroundColor(.mainTextApp)

            TextField("Минуты", text: $customMinutesInput)
                .textFieldStyle(.roundedBorder)
                .font(Font.custom("HSESans-Regular", size: 14))
                .frame(width: 120)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Отмена") {
                    showCustomTimeSheet = false
                }
                .applySecondaryButton()

                Button("Сохранить") {
                    if let minutes = Int(customMinutesInput), minutes > 0 {
                        selectedMinutes = minutes
                    }
                    showCustomTimeSheet = false
                }
                .applyPrimaryButton()
            }
        }
        .padding(24)
        .background(Color.blackApp)
        .frame(width: 250)
    }

    // MARK: Actions

    private func startTimer() {
        let duration = TimeInterval(selectedMinutes * 60)
        service.start(taskID: nil, taskTitle: taskTitle, duration: duration)
    }

    // MARK: Time formatting

    private func formattedRemaining() -> String {
        if service.isRunning() || service.isPaused() {
            let t = service.secondsRemaining()
            return String(format: "%02d:%02d", t / 60, t % 60)
        }
        return String(format: "%02d:00", selectedMinutes)
    }

    private func formatHHMM(from seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60

        if h > 0 {
            return String(format: "%02d ч %02d мин", h, m)
        } else {
            return String(format: "%02d мин", m)
        }
    }
}


// MARK: Buttons

fileprivate extension Button {
    func applyPrimaryButton() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }

    func applySecondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}

fileprivate struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.custom("HSESans-SemiBold", size: 14))
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.grayApp.opacity(configuration.isPressed ? 0.8 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

fileprivate struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.custom("HSESans-Regular", size: 14))
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.lightGrayApp.opacity(configuration.isPressed ? 0.9 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
