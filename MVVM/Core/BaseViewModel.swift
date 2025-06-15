//
//  BaseViewModel.swift
//  MVVM
//
//  Created by Bishanm on 2025-06-08.
//

import Foundation

@MainActor
class BaseViewModel<ActionId: ActionIdType>: ObservableObject {
    /// Tracks loading states for each action
    @Published private(set) var loadingStates: [ActionId: Bool] = [:]
    
    /// Stores error messages for each action
    @Published private(set) var errorMessages: [ActionId: String] = [:]
    
    /// General error message for UI display (can be bound to alerts, etc.)
    @Published var errorMessage: String? = nil
    
    /// Sets the loading state for a specific action
    /// - Parameters:
    ///   - isLoading: Whether the action is currently loading
    ///   - actionId: The identifier of the action
    func setLoading(_ isLoading: Bool, for actionId: ActionId) {
        loadingStates[actionId] = isLoading
        onStatusUpdate(actionId: actionId, isLoading: isLoading)
    }
    
    /// Returns the current loading state of a specific action
    /// - Parameter actionId: The identifier of the action
    /// - Returns: `true` if the action is loading, `false` otherwise
    func isLoading(for actionId: ActionId) -> Bool {
        return loadingStates[actionId] ?? false
    }
    
    /// Returns the error message associated with a specific actionId, if any.
    /// This allows views to display errors for individual async actions separately.
    func error(for actionId: ActionId) -> String? {
        return errorMessages[actionId]
    }
    
    /// Dispatches an async task associated with an actionId
    /// Manages loading states, success, error handling, and optional finished callback
    /// - Parameters:
    ///   - actionId: The identifier for the async action
    ///   - task: The async closure to execute
    ///   - onFinished: Optional closure called when the task completes, with the result or nil if failed
    func dispatch<T>(
        actionId: ActionId,
        task: @escaping () async throws -> T,
        onFinished: ((T?) -> Void)? = nil
    ) {
        setLoading(true, for: actionId)
        
        Task {
            do {
                let result = try await task()
                await MainActor.run {
                    self.onSuccess(actionId: actionId, result: result)
                    onFinished?(result)
                    self.setLoading(false, for: actionId)
                }
            } catch {
                await MainActor.run {
                    self.onError(actionId: actionId, error: error)
                    onFinished?(nil)
                    self.setLoading(false, for: actionId)
                }
            }
        }
    }
    
    /// Dispatches multiple async tasks in parallel, tracking each action individually.
    /// Calls the completion with success and failure lists when all tasks are done.
    /// - Parameters:
    ///   - actionsWithTasks: Array of (ActionId, async task)
    ///   - onFinishedAll: Closure with success/failure ActionId arrays
    func dispatchGroup<T>(
        _ actionsWithTasks: [(ActionId, () async throws -> T)],
        onFinishedAll: @escaping (_ success: [ActionId], _ failure: [ActionId]) -> Void
    ) {
        let group = DispatchGroup()
        var successActions: [ActionId] = []
        var failedActions: [ActionId] = []
        let lock = NSLock()

        for (actionId, task) in actionsWithTasks {
            group.enter()
            dispatch(actionId: actionId, task: task) { result in
                lock.lock()
                if result != nil {
                    successActions.append(actionId)
                } else {
                    failedActions.append(actionId)
                }
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            onFinishedAll(successActions, failedActions)
        }
    }
    
    // MARK: overriding methods from child view modela
    
    /// Called when the async task completes successfully
    /// Override this method in subclasses to handle specific actions and update properties accordingly
    /// - Parameters:
    ///   - actionId: The identifier of the action that succeeded
    ///   - result: The result returned by the async task
    func onSuccess<T>(actionId: ActionId, result: T) {}
    
    /// Called when the async task fails with an error
    /// Override this method in subclasses to handle errors for specific actions
    /// - Parameters:
    ///   - actionId: The identifier of the action that failed
    ///   - error: The error returned by the async task
    func onError(actionId: ActionId, error: Error) {
        errorMessages[actionId] = error.localizedDescription
        errorMessage = error.localizedDescription
    }
    
    /// Optional hook for reacting to loading state changes per action
    /// Override in subclasses if you want to track or react to loading status updates
    /// - Parameters:
    ///   - actionId: The identifier of the action
    ///   - isLoading: Current loading state
    func onStatusUpdate(actionId: ActionId, isLoading: Bool) {}
}
