import Foundation

@MainActor
final class PullPresenter: PullPresenting {
    private let viewModel: PullViewModel

    init(viewModel: PullViewModel) {
        self.viewModel = viewModel
    }

    nonisolated func present(_ response: PullResponse) {
        Task { @MainActor in
            viewModel.errorMessage = nil

            switch response {
            case .loading(let isLoading):
                viewModel.isLoading = isLoading
                if isLoading {
                    viewModel.restoreSuccess = false
                    viewModel.errorMessage = nil
                }
            case .manifestLoaded(let manifest):
                viewModel.manifest = manifest
            case .remoteSettingsLoaded(let remote, let localCategories):
                viewModel.isLoading = false
                viewModel.isFetched = true
                let remoteCategories = Array(remote.availableCategories()).sorted { $0.rawValue < $1.rawValue }
                viewModel.restoreOptions = remoteCategories.map { category in
                    RestoreOption(
                        category: category,
                        isSelected: category.isDefaultEnabled,
                        existsLocally: localCategories.contains(category)
                    )
                }
            case .restoreCompleted(let backupURL):
                viewModel.isRestoring = false
                viewModel.isLoading = false
                viewModel.restoreSuccess = true
                viewModel.backupURL = backupURL
                viewModel.progressMessage = ""
            case .restoreProgress(let message):
                viewModel.isRestoring = true
                viewModel.progressMessage = message
            }
        }
    }

    nonisolated func presentError(_ error: Error) {
        Task { @MainActor in
            viewModel.isLoading = false
            viewModel.isRestoring = false
            viewModel.progressMessage = ""
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
