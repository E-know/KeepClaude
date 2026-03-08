import SwiftUI

struct PullView: View {
    let interactor: any PullInteracting
    @State var viewModel: PullViewModel

    var body: some View {
        HSplitView {
            // Left: Repo input + fetch
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("원격 저장소") {
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
                        .disabled(viewModel.parsedRepo == nil || viewModel.isLoading)
                    }
                    .padding(.vertical, 4)
                }

                if viewModel.isFetched {
                    GroupBox("복원 항목") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.restoreOptions) { option in
                                Toggle(isOn: optionBinding(for: option.category)) {
                                    HStack {
                                        Label(option.category.displayName, systemImage: option.category.iconName)
                                        if option.existsLocally {
                                            Text("(로컬에 존재)")
                                                .font(.caption)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Spacer()

                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if viewModel.restoreSuccess {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("복원 완료!", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            if let url = viewModel.backupURL {
                                Text("백업: \(url.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if viewModel.isRestoring {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text(viewModel.progressMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

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
                            LabeledContent("플러그인", value: "\(manifest.summary.pluginCount)개")
                            LabeledContent("스킬", value: "\(manifest.summary.skillCount)개")
                            LabeledContent("커맨드", value: "\(manifest.summary.commandCount)개")
                            LabeledContent("사운드", value: "\(manifest.summary.soundCount)개")
                        }
                        Section("카테고리") {
                            ForEach(manifest.categories.sorted(by: { $0.key < $1.key }), id: \.key) { key, enabled in
                                LabeledContent(key, value: enabled ? "포함" : "미포함")
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
