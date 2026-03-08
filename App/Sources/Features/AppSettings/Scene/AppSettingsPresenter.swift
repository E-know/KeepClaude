import Foundation

@MainActor
final class AppSettingsPresenter: AppSettingsPresenting {
    private let viewModel: AppSettingsViewModel

    init(viewModel: AppSettingsViewModel) {
        self.viewModel = viewModel
    }

    nonisolated func present(_ response: AppSettingsResponse) {
        Task { @MainActor in
            viewModel.isLoading = false
            viewModel.errorMessage = nil
            viewModel.successMessage = nil

            switch response {
            case .authStatus(let isAuth, let user):
                viewModel.isAuthenticated = isAuth
                viewModel.currentUser = user
            case .connected(let user):
                viewModel.isAuthenticated = true
                viewModel.currentUser = user
                viewModel.tokenInput = ""
                viewModel.successMessage = "GitHub에 연결되었습니다."
            case .disconnected:
                viewModel.isAuthenticated = false
                viewModel.currentUser = nil
                viewModel.successMessage = "GitHub 연결이 해제되었습니다."
            case .loading(let isLoading):
                viewModel.isLoading = isLoading
            }
        }
    }

    nonisolated func presentError(_ error: Error) {
        Task { @MainActor in
            viewModel.isLoading = false
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
