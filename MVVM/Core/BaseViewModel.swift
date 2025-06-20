//
//  BaseViewModel.swift
//  PickMePassenger
//
//  Created by Bishan on 2025-06-08.
//

/**
 ===================================================================
 WARNING:
 -------------------------------------------------------------------
 This file contains core logic shared across the entire architecture.
 Changes to this file could be catastrophic to the entire project.
 Handle with extreme caution.
 ===================================================================
 
 Architecture Overview:
 This file is part of the SwiftUI-MVVM-UDF-Architecture:
 https://github.com/gayanthabishan/SwiftUI-MVVM-UDF-Architecture
 
 A lightweight, action-based unidirectional data flow (UDF) architecture
 without centralized state management. It simplifies asynchronous flow
 handling within SwiftUI's MVVM layer while preserving clarity and testability.
 
 This project is a minimal version of:
 https://github.com/gayanthabishan/SwiftUI-UDF-Architecture
 A fully-fledged UDF architecture with centralized state, middleware,
 and side-effects handling.
 
 Responsibilities of BaseViewModel:
 - Defines a generic `ActionId`-driven architecture for representing async user intentions
 - Provides a standardized way to dispatch async tasks via `dispatch(...)`
 - Offers `dispatchGroup(...)` to run multiple async tasks in parallel and wait for all to complete
 - Useful for screen-level loaders (e.g., one shimmer until all data loads)
 - Automatically tracks success/failure of each action
 - Manages per-action loading states (`loadingStates`) with @Published updates
 - Tracks per-action error messages (`errorMessages`) and a general UI-bound error (`errorMessage`)
 - Offers overridable hooks:
 - `onSuccess` to handle successful responses
 - `onError` to handle error cases
 - `onStatusUpdate` for loading state changes
 - Ensures all UI updates and published changes happen on the main actor
 - Encapsulates UI-safe logic and avoids duplication across ViewModels
 */

import Foundation

@MainActor
class BaseViewModel<ActionId: ActionIdType, UIAction: UIActionType>: ObservableObject {
    /// Tracks loading states for each action
    @Published private(set) var loadingStates: [ActionId: Bool] = [:]
    
    /// Stores error messages for each action
    @Published private(set) var errorMessages: [ActionId: String] = [:]
    
    /// General error message for UI display (can be bound to alerts, etc.)
    @Published var errorMessage: String? = nil
    
    /// Optional hook for observing errors (used in tests or subclass logic)
    var onErrorSet: (() -> Void)?
    
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
    
    // MARK: overriding methods from child view models
    
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
        onErrorSet?()
    }
    
    /// Optional hook for reacting to loading state changes per action
    /// Override in subclasses if you want to track or react to loading status updates
    /// - Parameters:
    ///   - actionId: The identifier of the action
    ///   - isLoading: Current loading state
    func onStatusUpdate(actionId: ActionId, isLoading: Bool) {}
    
    
    // MARK: helper methods
    
    /// Wraps an async throwing task to ignore its result and return `Void`.
    /// Useful for `dispatchGroup` when result is not needed but `try await` is required.
    ///
    /// Example:
    /// wrap { try await fetchSomething() }
    func wrap<T>(_ asyncThrowing: @escaping () async throws -> T) -> () async throws -> Void {
        return {
            _ = try await asyncThrowing()
        }
    }
    
    // MARK: Button action tracking
    
    /// Centralized UI action tracking (non-fetch)
    func dispatchUIAction(_ action: UIAction) {
        onUIAction(action)
        logUIAction(action)
    }
    
    /// Button clicks should trigger this inorder to dispatch the action
    func triggerUIAction(actionId: UIAction) { dispatchUIAction(actionId) }
    
    /// Optional override to let subclasses respond to UI actions
    /// Override in subclasses if needed
    func onUIAction(_ action: UIAction) {}
    
    /// Analytics/logging layer for UI actions
    func logUIAction(_ action: UIAction) {
        print("[Analytics] UIAction: \(action.analyticsEventInfo.name) \(action.analyticsEventInfo.timeStamp)")
        // Plug into Firebase, Mixpanel, etc.
    }
    
}

