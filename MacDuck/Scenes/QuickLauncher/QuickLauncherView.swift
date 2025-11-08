//
//  QuickLauncherView.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import SwiftUI
import AppKit

struct QuickLauncherView: View {
    @StateObject private var viewModel = QuickLauncherViewModel()
    @FocusState private var isSearchFocused: Bool
    @State private var selectedIndex: Int = 0
    @State private var scrollProxy: ScrollViewProxy?
    @State private var lastTappedIndex: Int? = nil
    private let itemHeight: CGFloat = 52
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search field - более компактный как в старом Spotlight
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondaryTextApp)
                    .font(.system(size: 16))
                    .frame(width: 16)
                
                TextField("Поиск", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.mainTextApp)
                    .focused($isSearchFocused)
                    .onSubmit {
                        if !viewModel.filteredCommands.isEmpty {
                            executeSelectedCommand()
                        }
                    }
                    .onKeyPress(.escape) {
                        QuickLauncherWindow.shared.hide()
                        return .handled
                    }
                    .onKeyPress(.return) {
                        if !viewModel.filteredCommands.isEmpty {
                            executeSelectedCommand()
                            return .handled
                        }
                        return .ignored
                    }
                    .onKeyPress(.downArrow) {
                        if selectedIndex < viewModel.filteredCommands.count - 1 {
                            selectedIndex += 1
                            scrollToItem(selectedIndex)
                        }
                        return .handled
                    }
                    .onKeyPress(.upArrow) {
                        if selectedIndex > 0 {
                            selectedIndex -= 1
                            scrollToItem(selectedIndex)
                        }
                        return .handled
                    }
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.clearSearch()
                        selectedIndex = 0
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondaryTextApp)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Results list
            if viewModel.filteredCommands.isEmpty && !viewModel.searchText.isEmpty {
                GeometryReader { geometry in
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundColor(.secondaryTextApp)
                        Text("Ничего не найдено")
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryTextApp)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .padding(.vertical, 30)
                }
            } else if !viewModel.filteredCommands.isEmpty {
                Divider()
                    .background(Color.borderApp.opacity(0.3))
                
                GeometryReader { geometry in
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                // Вычисляем индексы для категорий
                                let appsCount = viewModel.groupedCommands.applications.count
                                let filesCount = viewModel.groupedCommands.files.count
                                
                                // Приложения
                                if appsCount > 0 {
                                    CategorySection(
                                        title: CommandCategory.applications.rawValue,
                                        commands: viewModel.groupedCommands.applications,
                                        startIndex: 0,
                                        selectedIndex: $selectedIndex,
                                        itemHeight: itemHeight,
                                        onTap: handleItemTap
                                    )
                                }
                                
                                // Файлы
                                if filesCount > 0 {
                                    CategorySection(
                                        title: CommandCategory.files.rawValue,
                                        commands: viewModel.groupedCommands.files,
                                        startIndex: appsCount,
                                        selectedIndex: $selectedIndex,
                                        itemHeight: itemHeight,
                                        onTap: handleItemTap
                                    )
                                }
                            }
                        }
                        .frame(height: geometry.size.height)
                        .scrollIndicators(.hidden)
                        .onAppear {
                            scrollProxy = proxy
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)
        )
        .onAppear {
            // Устанавливаем фокус на поле поиска с небольшой задержкой
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isSearchFocused = true
            }
            selectedIndex = 0
        }
        .onChange(of: isSearchFocused) { focused in
            // Выделяем весь текст при получении фокуса, если нужно
            if focused && viewModel.shouldSelectAll {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectAllText()
                    viewModel.shouldSelectAll = false
                }
            }
        }
        .onChange(of: viewModel.searchText) {
            selectedIndex = 0
            lastTappedIndex = nil
        }
        .onChange(of: viewModel.filteredCommands.count) {
            if selectedIndex >= viewModel.filteredCommands.count {
                selectedIndex = max(0, viewModel.filteredCommands.count - 1)
            }
        }
    }
    
    private func executeSelectedCommand() {
        guard selectedIndex < viewModel.filteredCommands.count else { return }
        let command = viewModel.filteredCommands[selectedIndex]
        viewModel.executeCommand(command)
        QuickLauncherWindow.shared.hide()
    }
    
    private func scrollToItem(_ index: Int) {
        if let proxy = scrollProxy {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(index, anchor: .center)
            }
        }
    }
    
    private func selectAllText() {
        // Находим NSTextField в иерархии view и выделяем весь текст
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if let window = NSApplication.shared.keyWindow as? QuickLauncherWindow,
               let contentView = window.contentView {
                findAndSelectTextField(in: contentView)
            }
        }
    }
    
    private func findAndSelectTextField(in view: NSView) {
        // Проверяем, является ли view NSTextField
        if let textField = view as? NSTextField {
            if textField.isEditable {
                textField.selectText(nil)
                return
            }
        }
        
        // Рекурсивно ищем в подвью
        for subview in view.subviews {
            findAndSelectTextField(in: subview)
        }
    }
    
    private func handleItemTap(at index: Int, command: LauncherCommand) {
        // Если это второй тап на том же элементе - выполняем команду
        if lastTappedIndex == index {
            viewModel.executeCommand(command)
            QuickLauncherWindow.shared.hide()
            lastTappedIndex = nil
        } else {
            // Первый тап - выбираем элемент (без прокрутки, только подсветка)
            selectedIndex = index
            lastTappedIndex = index
            
            // Сбрасываем выбор через некоторое время, если не было второго тапа
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if lastTappedIndex == index {
                    lastTappedIndex = nil
                }
            }
        }
    }
}

struct CategorySection: View {
    let title: String
    let commands: [LauncherCommand]
    let startIndex: Int
    @Binding var selectedIndex: Int
    let itemHeight: CGFloat
    let onTap: (Int, LauncherCommand) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Заголовок категории
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondaryTextApp)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
            
            // Элементы категории
            ForEach(Array(commands.enumerated()), id: \.element.id) { localIndex, command in
                let globalIndex = startIndex + localIndex
                CommandRowView(
                    command: command,
                    isSelected: globalIndex == selectedIndex
                )
                .frame(height: itemHeight)
                .id(globalIndex)
                .onTapGesture {
                    onTap(globalIndex, command)
                }
            }
        }
    }
}

struct CommandRowView: View {
    let command: LauncherCommand
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Показываем реальную иконку приложения или системную иконку
            if let appIcon = command.appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: command.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blueAccent)
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(command.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.mainTextApp)
                
                if !command.description.isEmpty {
                    Text(command.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryTextApp)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isSelected ? Color.blueAccent.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

#Preview {
    QuickLauncherView()
        .background(Color.blackApp)
}
