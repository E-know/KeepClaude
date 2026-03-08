import SwiftUI

enum DashboardConfigurator {
    @MainActor
    static func configure() -> DashboardView {
        let viewModel = DashboardViewModel()
        let fileSystemService: any FileSystemServicing = FileSystemService()
        let settingsRepo: any ClaudeSettingsRepositoryProtocol =
            ClaudeSettingsRepository(fileSystemService: fileSystemService)
        let scanWorker: any SettingsScanWorking =
            SettingsScanWorker(settingsRepository: settingsRepo)
        let presenter: any DashboardPresenting =
            DashboardPresenter(viewModel: viewModel)
        let interactor: any DashboardInteracting =
            DashboardInteractor(presenter: presenter, scanWorker: scanWorker)
        return DashboardView(interactor: interactor, viewModel: viewModel)
    }
}
