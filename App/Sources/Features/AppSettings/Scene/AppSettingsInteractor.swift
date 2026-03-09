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
            if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
               let first = languages.first,
               let appLang = AppLanguage(rawValue: first) {
                presenter.present(.currentLanguage(appLang))
            } else {
                presenter.present(.currentLanguage(.system))
            }
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
        case .changeLanguage(let language):
            if language == .system {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
            }
            presenter.present(.languageChanged)
        }
    }
}
