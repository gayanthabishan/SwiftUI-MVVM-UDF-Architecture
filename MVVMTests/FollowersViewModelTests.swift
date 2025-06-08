//
//  MVVMTests.swift
//  MVVMTests
//
//  Created by Bishanm on 2025-06-08.
//

import XCTest
@testable import MVVM

// MARK: - Mock Service conforming to NetworkServiceType
class MockNetworkService: NetworkServiceType {
    var shouldFail = false
    
    // Simulates network call to fetch followers
    func fetchFollowers(username: String) async throws -> [Follower] {
        if shouldFail {
            // Simulate network error
            throw URLError(.notConnectedToInternet)
        }
        // Return fake follower data
        return [Follower(id: 1, login: "mockUser", avatar_url: "https://example.com/avatar.png")]
    }
}

// MARK: - Unit Test
@MainActor
final class FollowersViewModelTests: XCTestCase {
    
    // Custom ViewModel to track loading states
    class TrackingViewModel: FollowersViewModel {
        var statusEvents: [(FollowersActionId, Bool)] = []
        
        // Capture every loading state change
        override func onStatusUpdate(actionId: FollowersActionId, isLoading: Bool) {
            statusEvents.append((actionId, isLoading))
            super.onStatusUpdate(actionId: actionId, isLoading: isLoading)
        }
    }
    
    // Test: Should track start and end of loading for getFollowers
    func test_actionLifecycle_for_fetchFollowers() async {
        let mockService = MockNetworkService()
        let viewModel = TrackingViewModel(service: mockService)
        
        // Start loading
        viewModel.getFollowers(for: "anyUser")
        
        // Wait for fetch to complete
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Check that we got two events: start (true) and end (false)
        XCTAssertEqual(viewModel.statusEvents.count, 2, "Expected 2 lifecycle events (start and end)")
        XCTAssertEqual(viewModel.statusEvents.first?.1, true, "First event should be loading = true")
        XCTAssertEqual(viewModel.statusEvents.last?.1, false, "Second event should be loading = false")
    }
    
    // Test: Should fetch followers successfully
    func test_getFollowers_success() async {
        let mockService = MockNetworkService()
        let viewModel = FollowersViewModel(service: mockService)
        
        // Should not be loading before fetch
        XCTAssertFalse(viewModel.isLoading(for: .fetchFollowers))
        
        let expectation = XCTestExpectation(description: "Should complete fetching followers")
        viewModel.getFollowers(for: "anyUser")
        
        // Wait for fetch to complete
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Should stop loading and have correct data
        XCTAssertFalse(viewModel.isLoading(for: .fetchFollowers))
        XCTAssertNil(viewModel.error(for: .fetchFollowers))
        XCTAssertEqual(viewModel.followers.count, 1)
        XCTAssertEqual(viewModel.followers.first?.login, "mockUser")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 3.0)
    }
    
    // Test: Should handle error when fetch fails
    func test_getFollowers_failure() async {
        let mockService = MockNetworkService()
        mockService.shouldFail = true
        let viewModel = FollowersViewModel(service: mockService)
        
        let expectation = XCTestExpectation(description: "Should handle error when fetch fails")
        viewModel.getFollowers(for: "anyUser")
        
        // Wait for fetch to complete
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Should stop loading and return an error
        XCTAssertFalse(viewModel.isLoading(for: .fetchFollowers))
        XCTAssertNotNil(viewModel.error(for: .fetchFollowers))
        XCTAssertTrue(viewModel.followers.isEmpty)
        XCTAssertTrue(viewModel.error(for: .fetchFollowers)?.contains("offline") ?? true)
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 3.0)
    }
}


