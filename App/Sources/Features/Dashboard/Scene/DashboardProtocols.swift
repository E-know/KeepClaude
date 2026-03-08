import Foundation

protocol DashboardInteracting: AnyObject, Sendable {
    func handleAction(_ action: DashboardAction)
}

protocol DashboardPresenting: AnyObject, Sendable {
    func present(_ response: DashboardResponse)
    func presentError(_ error: Error)
}
