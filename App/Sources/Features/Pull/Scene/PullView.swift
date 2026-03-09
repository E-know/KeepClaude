import SwiftUI

struct PullView: View {
    let interactor: any PullInteracting
    @State var viewModel: PullViewModel

    var body: some View {
        HSplitView {
            // Left: Repo input + fetch
            VStack(alignment: .leading, spacing: 16) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("https://github.com/user/repo", text: $viewModel.repoURL)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            if let parsed = viewModel.parsedRepo {
                                interactor.handleAction(.fetchRemote(owner: parsed.owner, repo: parsed.repo))
                            }
                        } label: {
                            Label("불러오기", systemImage: "arrow.down.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(viewModel.parsedRepo == nil || viewModel.isLoading)
                    }
                    .padding(.vertical, 8)
                } label: {
                    Label("원격 저장소", systemImage: "externaldrive.connected.to.line.below")
                        .font(.headline)
                }

                if viewModel.isFetched {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.restoreOptions) { option in
                                Toggle(isOn: optionBinding(for: option.category)) {
                                    HStack {
                                        Label(option.category.displayName, systemImage: option.category.iconName)
                                        if option.existsLocally {
                                            Text("(로컬에 존재)")
                                                .font(.callout)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Label("복원 항목", systemImage: "arrow.down.doc")
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

                        if viewModel.restoreSuccess {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("복원 완료!", systemImage: "checkmark.circle.fill")
                                    .font(.callout)
                                    .foregroundStyle(.green)
                                if let url = viewModel.backupURL {
                                    Text("백업: \(url.lastPathComponent)")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .transition(.opacity)
                        }

                        if viewModel.isRestoring {
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
                    .animation(.easeInOut(duration: 0.2), value: viewModel.restoreSuccess)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isRestoring)

                    Button {
                        let selected = Set(viewModel.restoreOptions.filter(\.isSelected).map(\.category))
                        interactor.handleAction(.executeRestore(selected))
                    } label: {
                        Label("설정 복원", systemImage: "arrow.down.doc.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)
                    .disabled(
                        viewModel.restoreOptions.filter(\.isSelected).isEmpty
                        || viewModel.isRestoring
                    )
                } else {
                    Spacer()
                }
            }
            .padding()
            .frame(minWidth: 280, maxWidth: 320)

            // Right: Manifest info
            VStack {
                if viewModel.isLoading {
                    ProgressView("원격 설정 불러오는 중...")
                } else if let manifest = viewModel.manifest {
                    List {
                        Section("동기화 정보") {
                            LabeledContent("동기화 시각", value: manifest.syncedAt)
                            LabeledContent("동기화 사용자", value: manifest.syncedBy)
                            LabeledContent("플랫폼", value: "\(manifest.platform.os) \(manifest.platform.osVersion)")
                            LabeledContent("앱 버전", value: manifest.appVersion)
                        }
                        Section("요약") {
                            LabeledContent("플러그인", value: "\(manifest.summary.pluginCount)\(String(localized: "개"))")
                            LabeledContent("스킬", value: "\(manifest.summary.skillCount)\(String(localized: "개"))")
                            LabeledContent("커맨드", value: "\(manifest.summary.commandCount)\(String(localized: "개"))")
                            LabeledContent("사운드", value: "\(manifest.summary.soundCount)\(String(localized: "개"))")
                        }
                        Section("카테고리") {
                            ForEach(manifest.categories.sorted(by: { $0.key < $1.key }), id: \.key) { key, enabled in
                                LabeledContent(key, value: enabled ? String(localized: "포함") : String(localized: "미포함"))
                            }
                        }
                    }
                } else if !viewModel.isFetched {
                    ContentUnavailableView(
                        "저장소를 입력하세요",
                        systemImage: "arrow.down.circle",
                        description: Text("GitHub 저장소 URL을 입력한 후 불러오기를 눌러주세요.")
                    )
                } else {
                    ContentUnavailableView(
                        "매니페스트 없음",
                        systemImage: "doc.questionmark",
                        description: Text("원격 저장소에 manifest.json이 없습니다.")
                    )
                }
            }
            .frame(minWidth: 400)
        }
        .onAppear { interactor.handleAction(.onAppear) }
        .navigationTitle("불러오기 (Pull)")
    }

    private func optionBinding(for category: SettingsCategory) -> Binding<Bool> {
        Binding(
            get: {
                viewModel.restoreOptions.first { $0.category == category }?.isSelected ?? false
            },
            set: { isOn in
                if let idx = viewModel.restoreOptions.firstIndex(where: { $0.category == category }) {
                    viewModel.restoreOptions[idx].isSelected = isOn
                }
            }
        )
    }
}
