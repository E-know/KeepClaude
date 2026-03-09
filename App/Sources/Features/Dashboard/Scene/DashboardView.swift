import SwiftUI

struct DashboardView: View {
    let interactor: any DashboardInteracting
    @State var viewModel: DashboardViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("설정 파일 스캔 중...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.claudeDirExists {
                ContentUnavailableView(
                    "Claude Code 설정을 찾을 수 없습니다",
                    systemImage: "folder.badge.questionmark",
                    description: Text("~/.claude/ 디렉토리가 존재하지 않습니다.\nClaude Code를 먼저 설치해주세요.")
                )
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "오류 발생",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                List {
                    Section("~/.claude/") {
                        ForEach(viewModel.settingsTree) { node in
                            SettingsTreeRow(node: node)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .onAppear {
            interactor.handleAction(.onAppear)
        }
        .toolbar {
            ToolbarItem {
                Button("새로고침", systemImage: "arrow.clockwise") {
                    interactor.handleAction(.refresh)
                }
            }
        }
        .navigationTitle("설정 현황")
    }
}
