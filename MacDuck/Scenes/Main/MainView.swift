//
//  MainView.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import SwiftUI
import AppKit

enum Tab: String, Hashable {
    case taskManager = "Задачи"
    case timeManager = "Помодоро"
    case quickLauncher = "Быстрый поиск"
    case exchangeBuffer = "Буфер обмена"
}

struct MainView: View {
    @State var selectedTab: Tab = .taskManager
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: Tab.taskManager) {
                    Label(Tab.taskManager.rawValue, systemImage: "checklist")
                }
                
                NavigationLink(value: Tab.timeManager) {
                    Label(Tab.timeManager.rawValue, systemImage: "timer")
                }
                
                NavigationLink(value: Tab.quickLauncher) {
                    Label(Tab.quickLauncher.rawValue, systemImage: "magnifyingglass")
                }
                
                NavigationLink(value: Tab.exchangeBuffer) {
                    Label(Tab.exchangeBuffer.rawValue, systemImage: "doc.on.clipboard")
                }
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 170)
            .background(Color(NSColor.windowBackgroundColor))
            .foregroundStyle(Color.mainTextApp)
        } detail: {
            Group {
                switch selectedTab {
                case .taskManager:
                    TaskManagerView()
                case .timeManager:
                    TimeManagerView()
                case .quickLauncher:
                    QuickLauncherSettingsView()
                case .exchangeBuffer:
                    ExchangeBufferView()
                }
            }
            .navigationTitle(selectedTab.rawValue)
        }
    }
}

// Заглушки
struct TaskManagerView: View {
    var body: some View {
        Text(Tab.taskManager.rawValue)
    }
}

struct TimeManagerView: View {
    var body: some View {
        Text(Tab.timeManager.rawValue)
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
