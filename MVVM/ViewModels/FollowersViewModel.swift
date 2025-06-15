//
//  FollowersViewModel.swift
//  MVVM
//
//  Created by Bishanm on 2025-06-08.
//

import Foundation

class FollowersViewModel: BaseViewModel<FollowersActionId> {
    
    //data
    @Published var followers: [Follower] = []
    
    //network injection
    private let service: NetworkServiceProtocol
    
    init(service: NetworkServiceProtocol = NetworkService()) {
        self.service = service
    }
    
    // Method to start fetching followers asynchronously
    func getFollowers(for username: String) {
        
        //suggested flow of just dispatching and catching results in onSuccess method
        dispatch(actionId: .fetchFollowers, task: {
            // Sleep for 1 second (1_000_000_000 nanoseconds)
            // just to demo the automated loader showing and dismissing
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return try await self.service.fetchFollowers(username: username)
        })
        
        /// **incase for some reason if you need to handle result right in the local method and do only the UI changes in onSuccess method**
        /*
        dispatch(actionId: .fetchFollowers, task: {
            try await self.service.fetchFollowers(username: username)
        }, onFinished: { [weak self] result in
            guard let followers = result else { return }
            self?.followers = followers
        })
         */
    }
    
    
    // MARK: - Example Usage of dispatchGroup in ViewModel
    /*
     This method demonstrates how to fetch multiple independent data sources
      in parallel using BaseViewModel's dispatchGroup(...) helper.

      It:
      - Automatically tracks individual loading/error states via `BaseViewModel.dispatch(...)`
      - Executes all tasks in parallel
      - Waits until all tasks complete (regardless of success or failure)
      - Hides the full-page loader once all tasks are done
      - Optionally handles any failed actionIds for retries or fallback logic

      Useful for scenarios like initial screen load where you show a shimmer/skeleton until all major data is ready.
     */
    /*
     @Published var isPageLoading = false
     func loadHomeScreen() {
         isPageLoading = true

         dispatchGroup([
             (.fetchBanners, fetchBanners),
             (.fetchCategories, fetchCategories),
             (.fetchEvents, fetchEvents)
         ]) { success, failure in
             self.isPageLoading = false

             if !failure.isEmpty {
                 print("Retry failed actions: \(failure)")
                 // You can show retry UI or log analytics here
             }
         }
     }
     */
    
    // Called on successful completion of any dispatch
    override func onSuccess<T>(actionId: FollowersActionId, result: T) {
        switch actionId {
        case .fetchFollowers:
            if let followers = result as? [Follower] {
                self.followers = followers
            }
            // You can update UI success here
        }
    }
    
    // Called on error for any dispatch
    override func onError(actionId: FollowersActionId, error: Error) {
        switch actionId {
        case .fetchFollowers:
            print("Failed to fetch followers: \(error.localizedDescription)")
            // You can update UI error state here or show alerts
        }
    }
    
    // Called whenever the loading state changes for a specific action
    // This is not mandotory to override but it's there if you need to do something while doing an action
    // example : centralized event trail hook to log or track the lifecycle of actions
    override func onStatusUpdate(actionId: FollowersActionId, isLoading: Bool) {
        switch actionId {
        case .fetchFollowers:
            print("Loading state for fetchFollowers is \(isLoading)")
        }
    }
}
