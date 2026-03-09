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
            presenter.present(.currentLanguage(currentLanguage))
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
            guard language != currentLanguage else { return }
            if language == .system {
                UserDefaults.standard.removeObject(forKey: Constants.appleLanguagesKey)
            } else {
                UserDefaults.standard.set([language.rawValue], forKey: Constants.appleLanguagesKey)
            }
            presenter.present(.languageChanged(language))
        }
    }

    private var currentLanguage: AppLanguage {
        if let languages = UserDefaults.standard.array(forKey: Constants.appleLanguagesKey) as? [String],
           let first = languages.first,
           let appLang = AppLanguage(rawValue: first) {
            return appLang
        }
        return .system
    }
}
