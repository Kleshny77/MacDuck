//
//  QuickLauncherViewModel.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import Foundation
import Combine

enum CommandCategory: String {
    case all = "Все результаты"
    case applications = "Приложения"
    case files = "Файлы"
}

struct GroupedCommands {
    var all: [LauncherCommand] = []
    var applications: [LauncherCommand] = []
    var files: [LauncherCommand] = []
}

class QuickLauncherViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet {
            UserDefaults.standard.set(searchText, forKey: "quickLauncherLastSearchText")
        }
    }
    @Published var filteredCommands: [LauncherCommand] = []
    @Published var groupedCommands: GroupedCommands = GroupedCommands()
    @Published var shouldSelectAll: Bool = false
    
    private let commandRegistry = CommandRegistry.shared
    private let lastSearchTextKey = "quickLauncherLastSearchText"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        if let lastText = UserDefaults.standard.string(forKey: lastSearchTextKey) {
            searchText = lastText
            shouldSelectAll = true
        }
        
        let allCommands = commandRegistry.getAllCommands()
        filteredCommands = allCommands
        groupedCommands = groupCommands(allCommands)
        
        $searchText
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] query in
                guard let self = self else { return [] }
                return self.commandRegistry.search(query)
            }
            .sink { [weak self] (commands: [LauncherCommand]) in
                guard let self = self else { return }
                self.filteredCommands = commands
                self.groupedCommands = self.groupCommands(commands)
            }
            .store(in: &cancellables)
    }
    
    func executeCommand(_ command: LauncherCommand) {
        command.execute()
    }
    
    func clearSearch() {
        searchText = ""
        UserDefaults.standard.removeObject(forKey: lastSearchTextKey)
    }
    
    private func groupCommands(_ commands: [LauncherCommand]) -> GroupedCommands {
        var grouped = GroupedCommands()
        grouped.all = commands
        
        for command in commands {
            if command is ApplicationCommand {
                grouped.applications.append(command)
            } else if command is FileCommand {
                grouped.files.append(command)
            }
        }
        
        return grouped
    }
}
