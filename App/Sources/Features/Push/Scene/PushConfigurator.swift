import SwiftUI

enum PushConfigurator {
    @MainActor
    static func configure() -> PushView {
        let viewModel = PushViewModel()
        let scanWorker: any SettingsScanWorking = SettingsScanWorker()
        let pushWorker: any GitHubPushWorking = GitHubPushWorker()
        let authWorker: any AuthWorking = AuthWorker()
        let presenter: any PushPresenting = PushPresenter(viewModel: viewModel)
        let interactor: any PushInteracting = PushInteractor(
            presenter: presenter,
            scanWorker: scanWorker,
            pushWorker: pushWorker,
            authWorker: authWorker
        )
        return PushView(interactor: interactor, viewModel: viewModel)
    }
}
