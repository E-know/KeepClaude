import SwiftUI

enum PullConfigurator {
    @MainActor
    static func configure() -> PullView {
        let viewModel = PullViewModel()
        let pullWorker: any GitHubPullWorking = GitHubPullWorker()
        let restoreWorker: any SettingsRestoreWorking = SettingsRestoreWorker()
        let scanWorker: any SettingsScanWorking = SettingsScanWorker()
        let presenter: any PullPresenting = PullPresenter(viewModel: viewModel)
        let interactor: any PullInteracting = PullInteractor(
            presenter: presenter,
            pullWorker: pullWorker,
            restoreWorker: restoreWorker,
            scanWorker: scanWorker
        )
        return PullView(interactor: interactor, viewModel: viewModel)
    }
}
