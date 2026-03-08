import Foundation

final class AppSettingsInteractor: AppSettingsInteracting, @unchecked Sendable {
    private let presenter: any AppSettingsPresenting
    private let authWorker: any AuthWorking

    init(presenter: any AppSettingsPresenting, authWorker: any AuthWorking) {
        self.presenter = presenter
        self.authWorker = authWorker
    }

    func handleAction(_ action: AppSettingsAction) {
        switch action {
        case .onAppear:
            Task {
                presenter.present(.loading(true))
                do {
                    let status = try await authWorker.checkAuthStatus()
                    presenter.present(.authStatus(
                        isAuthenticated: status.isAuthenticated,
                        user: status.user
                    ))
                } catch {
                    presenter.present(.authStatus(isAuthenticated: false, user: nil))
                }
            }
        case .connectGitHub(let token):
            Task {
                presenter.present(.loading(true))
                do {
                    let user = try await authWorker.authenticate(token: token)
                    presenter.present(.connected(user))
                } catch {
                    presenter.presentError(error)
                }
            }
        case .disconnectGitHub:
            do {
                try authWorker.deleteToken()
                presenter.present(.disconnected)
            } catch {
                presenter.presentError(error)
            }
        case .updateRepoName:
            break
        }
    }
}
