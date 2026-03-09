import SwiftUI

struct PushView: View {
    let interactor: any PushInteracting
    @State var viewModel: PushViewModel

    var body: some View {
        HSplitView {
            // Left: Category selection + commit message
            VStack(alignment: .leading, spacing: 16) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.availableCategories) { category in
                            Toggle(isOn: categoryBinding(for: category)) {
                                Label(category.displayName, systemImage: category.iconName)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } label: {
                    Label("동기화 항목", systemImage: "checklist")
                        .font(.headline)
                }

                GroupBox {
                    TextField("변경 사항을 설명하세요", text: $viewModel.commitMessage, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.plain)
                } label: {
                    Label("커밋 메시지", systemImage: "text.bubble")
                        .font(.headline)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.callout)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }

                    if viewModel.pushSuccess {
                        Label("Push 완료!", systemImage: "checkmark.circle.fill")
                            .font(.callout)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }

                    if viewModel.isPushing {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text(viewModel.progressMessage)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
                .animation(.easeInOut(duration: 0.2), value: viewModel.pushSuccess)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isPushing)

                Button {
                    interactor.handleAction(
                        .executePush(
                            categories: viewModel.selectedCategories,
                            message: viewModel.commitMessage
                        )
                    )
                } label: {
                    Label("GitHub에 저장", systemImage: "arrow.up.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(
                    viewModel.selectedCategories.isEmpty
                    || viewModel.commitMessage.isEmpty
                    || viewModel.isPushing
                    || !viewModel.isAuthenticated
                )
            }
            .padding()
            .frame(minWidth: 280, maxWidth: 320)

            // Right: Status
            VStack {
                if !viewModel.isAuthenticated {
                    ContentUnavailableView(
                        "GitHub 연결 필요",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text("설정 탭에서 GitHub Personal Access Token을 먼저 연결해주세요.")
                    )
                } else if viewModel.selectedCategories.isEmpty {
                    ContentUnavailableView(
                        "항목을 선택하세요",
                        systemImage: "checklist",
                        description: Text("왼쪽에서 동기화할 항목을 선택해주세요.")
                    )
                } else {
                    List {
                        Section("선택된 항목") {
                            ForEach(Array(viewModel.selectedCategories).sorted(by: { $0.rawValue < $1.rawValue })) { category in
                                Label(category.displayName, systemImage: category.iconName)
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 400)
        }
        .onAppear { interactor.handleAction(.onAppear) }
        .navigationTitle("GitHub에 저장")
    }

    private func categoryBinding(for category: SettingsCategory) -> Binding<Bool> {
        Binding(
            get: { viewModel.selectedCategories.contains(category) },
            set: { isOn in
                if isOn {
                    viewModel.selectedCategories.insert(category)
                } else {
                    viewModel.selectedCategories.remove(category)
                }
            }
        )
    }
}
