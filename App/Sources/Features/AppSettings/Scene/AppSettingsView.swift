import SwiftUI

struct AppSettingsView: View {
    let interactor: any AppSettingsInteracting
    @State var viewModel: AppSettingsViewModel

    var body: some View {
        Form {
            Section("언어") {
                Picker("앱 언어", selection: $viewModel.selectedLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .onChange(of: viewModel.selectedLanguage) { _, newValue in
                    interactor.handleAction(.changeLanguage(newValue))
                }
                if viewModel.showRestartMessage {
                    Label("언어 변경을 적용하려면 앱을 재시작해주세요.", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("GitHub 연결") {
                if viewModel.isAuthenticated, let user = viewModel.currentUser {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text(user.login).font(.headline)
                            if let name = user.name {
                                Text(name).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("연결 해제", role: .destructive) {
                            interactor.handleAction(.disconnectGitHub)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GitHub Personal Access Token")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            SecureField("ghp_xxxx...", text: $viewModel.tokenInput)
                                .textFieldStyle(.roundedBorder)
                            Button("연결") {
                                interactor.handleAction(.connectGitHub(token: viewModel.tokenInput))
                            }
                            .disabled(viewModel.tokenInput.isEmpty || viewModel.isLoading)
                        }
                        DisclosureGroup("필요한 권한 보기") {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Classic PAT", systemImage: "key")
                                    .font(.caption.bold())
                                Text("repo 권한을 선택하세요.")
                                    .font(.caption)
                                    .padding(.leading, 20)

                                Divider()

                                Label("Fine-grained PAT", systemImage: "key.viewfinder")
                                    .font(.caption.bold())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("• Contents: Read and Write")
                                    Text("• Metadata: Read")
                                }
                                .font(.caption)
                                .padding(.leading, 20)
                            }
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Section("저장소") {
                TextField("저장소 이름", text: $viewModel.repoName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.repoName) { _, newValue in
                        interactor.handleAction(.updateRepoName(newValue))
                    }
                Text("GitHub에 생성될 저장소 이름입니다.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            if let success = viewModel.successMessage {
                Section {
                    Label(success, systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { interactor.handleAction(.onAppear) }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("설정")
    }
}
