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
    var body: some View {
        Text(Tab.exchangeBuffer.rawValue)
    }
}

#Preview {
    MainView()
}
