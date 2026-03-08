import Foundation

protocol AppSettingsInteracting: AnyObject, Sendable {
    func handleAction(_ action: AppSettingsAction)
}

protocol AppSettingsPresenting: AnyObject, Sendable {
    func present(_ response: AppSettingsResponse)
    func presentError(_ error: Error)
}
