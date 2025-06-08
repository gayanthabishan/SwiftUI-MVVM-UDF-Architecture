
# SwiftUI MVVM Architecture with Centralized Async Action Handling

## Why This Pattern?

This approach enhances the **maintainability**, **readability**, and **debuggability** of SwiftUI apps which uses MVVM architecture.

### Benefits

- **Centralized Action Management**: All async actions go through a `dispatch` function in the `BaseViewModel`.
- **Automatic Loader Handling**: Easily show/hide loading indicators (e.g. spinners, shimmers) per action.
- **Centralized Error Handling**: Errors are tracked and exposed for each action via a clean API.
- **Centralize Lifecycle Tracking with `onStatusUpdate`**: Log or analyze when an action starts or finishes, audit trail.
- **Minimal Boilerplate**: Developers only write the logic unique to each `ViewModel` action.
- **Strong Separation of Concerns**: UI, ViewModel, and Service layers remain clearly separated.
- **Easy to adopt into current MVVM code**: just use the same folder structure, same network services etc and extends viewmodels with base.

### Unit Testing gains

- **Testable ViewModels**: Each ViewModel remains isolated and can be tested by injecting mock services.
- **Centralized Error & Loading Assertions:**: Easily verify loading states and errors with isLoading(for:) and error(for:)
- **Mockable Service Layer**: Service dependencies follow protocol-based abstraction, allowing clean mock injection for testing.
- **Action-Based State Tracking**: Actions are identified via ActionId, enabling precise testing of async behavior and results.
- **Decoupled Side Effects**: Success and failure paths (onSuccess, onError) are separate and testable without UI involvement.
- **Predictable Data Flow**: Unidirectional flow simplifies test setup and improves test determinism.
- **Easy State Verification**: No need to guess—just assert published values and track what changed and why.
- **Fully Unit test coverage with bolerplate code**: just use the same `FollowersViewModelTests.swift` as a boilerplate. Each action needs only three test cases for fully coverage. success, failure and lifecycle tracked.

## 📦 Folder Structure

```
MVVM
├── Views/
│   └── FollowersView.swift
├── ViewModels/
│   └── FollowersViewModel.swift
├── Base/
│   └── BaseViewModel.swift
│   └── ActionIdType.swift
├── Services/
│   └── NetworkService.swift
├── Models/
│   └── Follower.swift
MVVMTests/
│   └── FollowersViewModelTests.swift
```

## 🔄 Data Flow

```

```

1. **View** calls a function in the `ViewModel`
2. **ViewModel** uses `dispatch(actionId:task:)` to perform the async task
3. The loader state is automatically updated via `setLoading(true/false)`
4. The **Service** performs the network request
5. On success or error:
   - `onSuccess(actionId:result)` or `onError(actionId:error)` is called
   - `onStatusUpdate(actionId:isLoading:)` is invoked for tracking/logging
6. The **View** reacts to `@Published` states (data, loading, or error)

## 🧠 Layers Explained

### `BaseViewModel`

Handles:
- Loader state per action
- Error message per action
- Centralized dispatch with `Task { }`
- Hooks: `onSuccess`, `onError`, `onStatusUpdate`

### `ActionIdType`

A protocol to constrain enums like:

```swift
enum FollowersActionId: ActionIdType {
    case fetchFollowers
    case fetchUserProfile
}
```

### `FollowersViewModel`

Extends `BaseViewModel<FollowersActionId>` and overrides:
- `onSuccess` to update data state
- `onError` to handle errors
- `onStatusUpdate` for logging/tracking lifecycle

### `FollowersView`

A SwiftUI view that reacts to:
- `isLoading(for: .fetchFollowers)` to show shimmer/spinner
- `error(for: .fetchFollowers)` to show error message
- `@Published` data (`followers`) for UI display

## 🛠 How to Add a New Action

To fetch a new resource, e.g., **User Profile**:

### 1. Extend `ActionId` enum:

```swift
enum FollowersActionId: ActionIdType {
    case fetchFollowers
    case fetchUserProfile // ← new
}
```

### 2. Add method to ViewModel:

```swift
func getUserProfile(for username: String) {
    dispatch(actionId: .fetchUserProfile, task: {
        try await self.service.fetchUserProfile(username: username)
    })
}
```

### 3. Handle success/error:

```swift
override func onSuccess<T>(actionId: ActionId, result: T) {
    switch actionId {
    case .fetchUserProfile:
        if let profile = result as? UserProfile {
            self.userProfile = profile
        }
    default: break
    }
}

override func onError(actionId: ActionId, error: Error) {
    switch actionId {
    case .fetchUserProfile:
        print("Error fetching profile: \(error.localizedDescription)")
    default: break
    }
}
```

### 4. Update View:

```swift
if viewModel.isLoading(for: .fetchUserProfile) {
    ShimmerView()
} else if let error = viewModel.error(for: .fetchUserProfile) {
    Text("Error: \(error)")
} else {
    ProfileView(profile: viewModel.userProfile)
}
```

## 🔍 Tracking Events (Optional)

Override `onStatusUpdate` to track the status of actions:

```swift
override func onStatusUpdate(actionId: FollowersActionId, isLoading: Bool) {
    let status = isLoading ? "started" : "finished"
    print("[\(actionId)] \(status) at \(Date())")
}
```

Great for:
- Debugging sequence of events
- Logging durations
- Analytics pipelines

## ✨ Final Thoughts

This pattern scales well with apps that deal with multiple async states, API calls, and user-driven actions.

It allows **new developers to understand the flow quickly** while giving **senior developers full flexibility** and control over async logic and side effects.

## 📬 Contributions

PRs, issues, and ideas are welcome to improve this pattern further.
