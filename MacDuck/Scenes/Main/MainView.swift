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
    @State private var editingHotkeyItemId: ClipboardItem.ID?

    private let maxHotkeyIndex = 9

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.blackApp)
        .sheet(item: hotkeySheetBinding) { item in
            HotkeyAssignmentView(
                item: item,
                onSetHotkey: { hotkey in
                    service.setHotkey(hotkey, for: item)
                },
                onClearHotkey: {
                    service.setHotkey(nil, for: item)
                }
            )
        }
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
        let automaticShortcut = hotkey(for: index)
        let customShortcut = item.hotkey?.display

        ZStack(alignment: .topTrailing) {
            Button {
                service.paste(item)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(itemPreview(item))
                        .font(Font.custom("HSESans-Regular", size: 14))
                        .foregroundColor(.mainTextApp)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.capturedAt, style: .time)
                        .font(Font.custom("HSESans-Regular", size: 12))
                        .foregroundColor(.secondaryTextApp)
                }
                .padding(EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 90))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isHovered ? Color.grayApp : Color.cardBackgroundApp)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                hoveredId = hovering ? item.id : nil
            }
            .modifier(AutomaticShortcutModifier(index: index, limit: maxHotkeyIndex))

            VStack(alignment: .trailing, spacing: 6) {
                Button {
                    editingHotkeyItemId = item.id
                } label: {
                    Image(systemName: "keyboard")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondaryTextApp)
                        .padding(8)
                        .background(Color.grayApp.opacity(isHovered ? 0.9 : 0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                if let customShortcut {
                    shortcutBadge(customShortcut, isPrimary: true)
                } else if let automaticShortcut {
                    shortcutBadge(automaticShortcut, isPrimary: false)
                }
            }
            .padding(.top, 6)
            .padding(.trailing, 6)
        }
    }

    private func hotkey(for index: Int) -> String? {
        guard index < maxHotkeyIndex else { return nil }
        return "⌘\(index + 1)"
    }

    private func shortcutBadge(_ text: String, isPrimary: Bool) -> some View {
        Text(text)
            .font(Font.custom("HSESans-SemiBold", size: 12))
            .foregroundColor(isPrimary ? .black : .secondaryTextApp)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isPrimary ? Color.yellowAccent : Color.grayApp.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func itemPreview(_ item: ClipboardItem) -> String {
        let preview = item.preview
        if preview.isEmpty {
            return "Пустая строка"
        }
        return preview
    }

    private var hotkeySheetBinding: Binding<ClipboardItem?> {
        Binding(
            get: {
                guard let id = editingHotkeyItemId else { return nil }
                return service.items.first(where: { $0.id == id })
            },
            set: { newValue in
                editingHotkeyItemId = newValue?.id
            }
        )
    }
}

private struct AutomaticShortcutModifier: ViewModifier {
    let index: Int
    let limit: Int

    @ViewBuilder
    func body(content: Content) -> some View {
        if index < limit {
            content.keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [.command])
        } else {
            content
        }
    }
}

#Preview {
    MainView()
}
