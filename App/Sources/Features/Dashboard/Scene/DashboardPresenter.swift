import Foundation

@MainActor
final class DashboardPresenter: DashboardPresenting {
    private let viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    nonisolated func present(_ response: DashboardResponse) {
        Task { @MainActor in
            switch response {
            case .scanned(let settings):
                viewModel.settingsTree = SettingsTreeMapper.map(settings)
                viewModel.isLoading = false
                viewModel.claudeDirExists = true
                viewModel.errorMessage = nil
            case .loading(let isLoading):
                viewModel.isLoading = isLoading
                viewModel.errorMessage = nil
            }
        }
    }

    nonisolated func presentError(_ error: Error) {
        Task { @MainActor in
            viewModel.errorMessage = error.localizedDescription
            viewModel.isLoading = false
        }
    }
}
