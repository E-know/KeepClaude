import Foundation

protocol PushInteracting: AnyObject, Sendable {
    func handleAction(_ action: PushAction)
}

protocol PushPresenting: AnyObject, Sendable {
    func present(_ response: PushResponse)
    func presentError(_ error: Error)
}
