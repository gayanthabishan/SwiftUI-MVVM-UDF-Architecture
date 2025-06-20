//
//  FollowersActionId.swift
//  MVVM
//
//  Created by Bishanm on 2025-06-08.
//

// MARK: - Data fetching actions
enum FollowersActions: String, ActionIdType {
    case fetchFollowers
}

// MARK: - UI-only actions (taps, navigation, etc.)
enum FollowersUIActions: UIActionType {
    case tappedFollowersButton
    case tappedFollowersRetryButton
}

/*
 TODO: if we need seperate string for analytics use this
     enum FollowersUIActions: UIActionType {
         case tappedFollowers
         
         var analyticsEventName: String {
             switch self {
             case .tappedFollowers: return "tapped_followers"
             }
         }
     }
 */
