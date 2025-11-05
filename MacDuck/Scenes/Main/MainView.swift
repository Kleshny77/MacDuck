//
//  MainView.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import SwiftUI

enum Tab: String, Hashable {
    case taskManager = "Задачи"
    case timeManager = "Помодоро"
    case quickLauncher = "Быстрый поиск"
    case exchangeBuffer = "Буфер обмена"
}

struct MainView: View {
    @State private var selectedTab: Tab = .timeManager

    var body: some View {
        NavigationView {
            sidebar
            contentView
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    NSApp.keyWindow?.toggleSidebar(nil)
                } label: {
                    Image(systemName: "sidebar.left") // красивая иконка
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .help("Показать/скрыть панель")
            }
        }
        .frame(minWidth: 900, minHeight: 560)
        .background(Color.blackApp)
    }

    private var sidebar: some View {
        List(selection: $selectedTab) {
            Label(Tab.taskManager.rawValue, systemImage: "checklist")
                .tag(Tab.taskManager)
            Label(Tab.timeManager.rawValue, systemImage: "timer")
                .tag(Tab.timeManager)
            Label(Tab.quickLauncher.rawValue, systemImage: "magnifyingglass")
                .tag(Tab.quickLauncher)
            Label(Tab.exchangeBuffer.rawValue, systemImage: "doc.on.doc")
                .tag(Tab.exchangeBuffer)
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 220)
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .taskManager:
            TaskManagerView()
                .navigationTitle(Tab.taskManager.rawValue)
        case .timeManager:
            TimeManagerView()
                .navigationTitle(Tab.timeManager.rawValue)
        case .quickLauncher:
            QuickLauncherView()
                .navigationTitle(Tab.quickLauncher.rawValue)
        case .exchangeBuffer:
            ExchangeBufferView()
                .navigationTitle(Tab.exchangeBuffer.rawValue)
        }
    }
}

// Заглушки
struct TaskManagerView: View {
    var body: some View {
        Text(Tab.taskManager.rawValue)
    }
}

struct QuickLauncherView: View {
    var body: some View {
        Text(Tab.quickLauncher.rawValue)
    }
}

struct ExchangeBufferView: View {
    @ObservedObject private var service = ClipboardHistoryService.shared
    @State private var hoveredId: ClipboardItem.ID?

    private let maxHotkeyIndex = 9

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.blackApp)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("История буфера обмена")
                .font(Font.custom("HSESans-Bold", size: 22))
                .foregroundColor(.mainTextApp)

            Text("Выберите запись или нажмите сочетание клавиш, чтобы вставить содержимое в активное окно.")
                .font(Font.custom("HSESans-Regular", size: 13))
                .foregroundColor(.secondaryTextApp)
        }
    }

    @ViewBuilder
    private var content: some View {
        if service.items.isEmpty {
            emptyState
        } else {
            historyList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Пока здесь пусто")
                .font(Font.custom("HSESans-SemiBold", size: 16))
                .foregroundColor(.secondaryTextApp)

            Text("Скопируйте текст в любом приложении — он появится в истории.")
                .font(Font.custom("HSESans-Regular", size: 13))
                .foregroundColor(.secondaryTextApp)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(service.items.enumerated()), id: \.element.id) { index, item in
                    row(for: item, index: index)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for item: ClipboardItem, index: Int) -> some View {
        let isHovered = hoveredId == item.id
        let shortcut = hotkey(for: index)

        let label = HStack(alignment: .top, spacing: 12) {
            if let shortcut {
                Text(shortcut)
                    .font(Font.custom("HSESans-SemiBold", size: 12))
                    .foregroundColor(.secondaryTextApp)
                    .frame(width: 44, alignment: .leading)
            } else {
                Spacer()
                    .frame(width: 44)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(itemPreview(item))
                    .font(Font.custom("HSESans-Regular", size: 14))
                    .foregroundColor(.mainTextApp)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Text(item.capturedAt, style: .time)
                    .font(Font.custom("HSESans-Regular", size: 12))
                    .foregroundColor(.secondaryTextApp)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovered ? Color.grayApp : Color.cardBackgroundApp)
        .clipShape(RoundedRectangle(cornerRadius: 10))

        if index < maxHotkeyIndex {
            Button {
                service.paste(item)
            } label: {
                label
            }
            .buttonStyle(.plain)
            .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [.command])
            .onHover { hovering in
                hoveredId = hovering ? item.id : nil
            }
        } else {
            Button {
                service.paste(item)
            } label: {
                label
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                hoveredId = hovering ? item.id : nil
            }
        }
    }

    private func hotkey(for index: Int) -> String? {
        guard index < maxHotkeyIndex else { return nil }
        return "⌘\(index + 1)"
    }

    private func itemPreview(_ item: ClipboardItem) -> String {
        let preview = item.preview
        if preview.isEmpty {
            return "Пустая строка"
        }
        return preview
    }
}

#Preview {
    MainView()
}
