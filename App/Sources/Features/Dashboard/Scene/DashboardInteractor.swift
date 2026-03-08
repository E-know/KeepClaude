import Foundation

final class DashboardInteractor: DashboardInteracting, @unchecked Sendable {
    private let presenter: any DashboardPresenting
    private let scanWorker: any SettingsScanWorking

    init(presenter: any DashboardPresenting, scanWorker: any SettingsScanWorking) {
        self.presenter = presenter
        self.scanWorker = scanWorker
    }

    func handleAction(_ action: DashboardAction) {
        switch action {
        case .onAppear, .refresh:
            Task {
                presenter.present(.loading(true))
                do {
                    let settings = try await scanWorker.scanSettings()
                    presenter.present(.scanned(settings))
                } catch {
                    presenter.presentError(error)
                }
            }
        }
    }
}
