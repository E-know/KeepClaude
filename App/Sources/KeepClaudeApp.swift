import SwiftUI

@main
struct KeepClaudeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
    }
}

struct ContentView: View {
    @State private var selectedMenu: SidebarMenu = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedMenu)
        } detail: {
            switch selectedMenu {
            case .dashboard:
                DashboardConfigurator.configure()
            case .push:
                PushConfigurator.configure()
            case .pull:
                PullConfigurator.configure()
            case .settings:
                AppSettingsConfigurator.configure()
            }
        }
    }
}

enum SidebarMenu: String, CaseIterable, Identifiable {
    case dashboard
    case push
    case pull
    case settings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dashboard: "설정 현황"
        case .push: "저장 (Push)"
        case .pull: "불러오기 (Pull)"
        case .settings: "설정"
        }
    }

    var iconName: String {
        switch self {
        case .dashboard: "list.bullet.rectangle"
        case .push: "arrow.up.circle.fill"
        case .pull: "arrow.down.circle.fill"
        case .settings: "gearshape"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarMenu

    var body: some View {
        List(SidebarMenu.allCases, selection: $selection) { menu in
            Label(menu.displayName, systemImage: menu.iconName)
                .tag(menu)
        }
        .navigationTitle("KeepClaude")
    }
}
