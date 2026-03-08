import Foundation

final class PullInteractor: PullInteracting, @unchecked Sendable {
    private let presenter: any PullPresenting
    private let pullWorker: any GitHubPullWorking
    private let restoreWorker: any SettingsRestoreWorking
    private let scanWorker: any SettingsScanWorking

    private var remoteSettings: ClaudeSettings?

    init(
        presenter: any PullPresenting,
        pullWorker: any GitHubPullWorking,
        restoreWorker: any SettingsRestoreWorking,
        scanWorker: any SettingsScanWorking
    ) {
        self.presenter = presenter
        self.pullWorker = pullWorker
        self.restoreWorker = restoreWorker
        self.scanWorker = scanWorker
    }

    func handleAction(_ action: PullAction) {
        switch action {
        case .onAppear:
            break
        case .fetchRemote(let owner, let repo):
            fetchRemote(owner: owner, repo: repo)
        case .toggleCategory:
            break
        case .executeRestore(let categories):
            executeRestore(categories: categories)
        }
    }

    private func fetchRemote(owner: String, repo: String) {
        Task {
            presenter.present(.loading(true))
            do {
                let manifest = try await pullWorker.fetchManifest(owner: owner, repo: repo)
                presenter.present(.manifestLoaded(manifest))

                let remote = try await pullWorker.fetchRemote(owner: owner, repo: repo)
                self.remoteSettings = remote

                let local = try await scanWorker.scanSettings()
                let localCategories = local.availableCategories()
                presenter.present(.remoteSettingsLoaded(remote, localCategories: localCategories))
            } catch {
                presenter.presentError(error)
            }
        }
    }

    private func executeRestore(categories: Set<SettingsCategory>) {
        guard let remote = remoteSettings else { return }
        Task {
            presenter.present(.restoreProgress("백업 생성 중..."))
            do {
                let backupURL = try await restoreWorker.backup()
                presenter.present(.restoreProgress("설정 복원 중..."))
                try await restoreWorker.restore(remote, categories: categories)
                presenter.present(.restoreCompleted(backupURL: backupURL))
            } catch {
                presenter.presentError(error)
            }
        }
    }
}
