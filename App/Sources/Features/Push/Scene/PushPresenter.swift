import Foundation

@MainActor
final class PushPresenter: PushPresenting {
    private let viewModel: PushViewModel

    init(viewModel: PushViewModel) {
        self.viewModel = viewModel
    }

    nonisolated func present(_ response: PushResponse) {
        Task { @MainActor in
            viewModel.errorMessage = nil

            switch response {
            case .categoriesLoaded(let settings, let isAuth):
                viewModel.isLoading = false
                viewModel.isAuthenticated = isAuth
                let available = Array(settings.availableCategories()).sorted { $0.rawValue < $1.rawValue }
                viewModel.availableCategories = available
                viewModel.selectedCategories = Set(available.filter(\.isDefaultEnabled))
                if viewModel.commitMessage.isEmpty {
                    viewModel.commitMessage = "Claude Code 설정 동기화"
                }
            case .pushCompleted:
                viewModel.isPushing = false
                viewModel.isLoading = false
                viewModel.pushSuccess = true
                viewModel.progressMessage = ""
            case .loading(let isLoading):
                viewModel.isLoading = isLoading
                if isLoading {
                    viewModel.pushSuccess = false
                }
            case .pushProgress(let message):
                viewModel.isPushing = true
                viewModel.progressMessage = message
            }
        }
    }

    nonisolated func presentError(_ error: Error) {
        Task { @MainActor in
            viewModel.isLoading = false
            viewModel.isPushing = false
            viewModel.progressMessage = ""
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
