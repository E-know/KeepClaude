import Foundation

protocol PullInteracting: AnyObject, Sendable {
    func handleAction(_ action: PullAction)
}

protocol PullPresenting: AnyObject, Sendable {
    func present(_ response: PullResponse)
    func presentError(_ error: Error)
}
