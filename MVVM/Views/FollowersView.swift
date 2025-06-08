//
//  FollowersView.swift
//  MVVM
//
//  Created by Bishanm on 2025-06-08.
//

import SwiftUI

struct FollowersView: View {
    @StateObject private var viewModel = FollowersViewModel()
    
    var body: some View {
        NavigationView {
            // Here we check if the specific loader for fetching followers is active.
            // Since BaseViewModel tracks loading states per ActionId,
            // you can similarly track different loaders by passing other action IDs like .fetchBanner or .fetchCategory.
            if viewModel.isLoading(for: .fetchFollowers) {
                ProgressView("Loading...")  // Show loading spinner only for fetchFollowers action
            }
            // Show error message specifically for fetchFollowers action if any
            else if let error = viewModel.error(for: .fetchFollowers) {
                Text("Error: \(error)")
            } else {
                // Show followers list when not loading and no error for fetchFollowers
                List(viewModel.followers) { follower in
                    HStack {
                        AsyncImage(url: URL(string: follower.avatar_url)) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        Text(follower.login)
                    }
                }
            }
        }
        .navigationTitle("Followers")
        .onAppear {
            // Triggers loading followers, this will toggle the loader tracked by .fetchFollowers ActionId
            viewModel.getFollowers(for: "apple")
        }
    }
}

#Preview {
    FollowersView()
}
