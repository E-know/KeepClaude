import SwiftUI

enum AppSettingsConfigurator {
    @MainActor
    static func configure() -> AppSettingsView {
        let viewModel = AppSettingsViewModel()
        let authWorker: any AuthWorking = AuthWorker()
        let presenter: any AppSettingsPresenting = AppSettingsPresenter(viewModel: viewModel)
        let interactor: any AppSettingsInteracting =
            AppSettingsInteractor(presenter: presenter, authWorker: authWorker)
        return AppSettingsView(interactor: interactor, viewModel: viewModel)
    }
}
