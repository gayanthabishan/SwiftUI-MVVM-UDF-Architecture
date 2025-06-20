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
            VStack {
                if viewModel.isLoading(for: .fetchFollowers) {
                    ProgressView("Loading...")
                        .frame(maxHeight: .infinity)
                } else if let error = viewModel.error(for: .fetchFollowers) {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                        Button("Retry") {
                            viewModel.triggerUIAction(actionId: .tappedFollowersRetryButton)
                        }
                        .padding(.top)
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.followers.isEmpty {
                    VStack {
                        Text("No followers found.")
                            .foregroundColor(.gray)
                        Button("Load Followers") {
                            viewModel.triggerUIAction(actionId: .tappedFollowersButton)
                        }
                        .padding(.top)
                    }
                    .frame(maxHeight: .infinity)
                } else {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Followers")
    }
}

#Preview {
    FollowersView()
}
