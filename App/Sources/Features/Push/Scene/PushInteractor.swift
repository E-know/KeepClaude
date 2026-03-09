import Foundation

final class PushInteractor: PushInteracting, @unchecked Sendable {
    private let presenter: any PushPresenting
    private let scanWorker: any SettingsScanWorking
    private let pushWorker: any GitHubPushWorking
    private let authWorker: any AuthWorking

    init(
        presenter: any PushPresenting,
        scanWorker: any SettingsScanWorking,
        pushWorker: any GitHubPushWorking,
        authWorker: any AuthWorking
    ) {
        self.presenter = presenter
        self.scanWorker = scanWorker
        self.pushWorker = pushWorker
        self.authWorker = authWorker
    }

    func handleAction(_ action: PushAction) {
        switch action {
        case .onAppear:
            Task {
                presenter.present(.loading(true))
                do {
                    let status = try await authWorker.checkAuthStatus()
                    let settings = try await scanWorker.scanSettings()
                    presenter.present(.categoriesLoaded(settings, isAuthenticated: status.isAuthenticated))
                } catch {
                    presenter.presentError(error)
                }
            }
        case .toggleCategory, .updateCommitMessage:
            break
        case .executePush(let categories, let message):
            executePush(categories: categories, message: message)
        }
    }

    private func executePush(categories: Set<SettingsCategory>, message: String) {
        Task {
            presenter.present(.loading(true))
            presenter.present(.pushProgress(String(localized: "설정 업로드 중...")))
            do {
                try await pushWorker.push(categories: categories, message: message)
                presenter.present(.pushCompleted)
            } catch {
                presenter.presentError(error)
            }
        }
    }
}
