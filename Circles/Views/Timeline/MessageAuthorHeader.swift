//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  MessageAuthorHeader.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix

struct MessageAuthorHeader: View {
    @ObservedObject var user: Matrix.User
    //@ObservedObject var room: MatrixRoom
    
    var shield: some View {
        user.isVerified
            ? Image(systemName: "checkmark.shield")
                .foregroundColor(Color.green)
            : Image(systemName: "xmark.shield")
                .foregroundColor(Color.red)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            
            //profileImage
            ProfileImageView(user: user)
                //.resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text(user.displayName ?? user.id)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    HStack(alignment: .center, spacing: 0) {
                        //shield
                        Text(user.id)
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                            .lineLimit(1)
                    }
                }
            }
            
        }
        /*
        .contextMenu {
            Button(action: {
                user.verify()
            }) {
                Label("Verify User", systemImage: "checkmark.shield")
            }
        }
        */
        .padding(.leading, 2)
        .onAppear {
            if user.avatarUrl == nil || user.displayName == nil {
                Task {
                    try await user.refreshProfile()
                }
            }
            if user.avatar == nil && user.avatarUrl != nil {
                Task {
                    try await user.fetchAvatarImage()
                }
            }
        }
    }
}

struct DummyMessageAuthorHeader: View {
    var userId: String? = nil
    
    var body: some View {
        HStack(alignment: .top) {
            
            //profileImage
            Image(systemName: "person.crop.square")
                .resizable()
                .frame(width: 40, height: 40)
                .scaledToFit()
                //.clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundColor(.gray)

            
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text(userId ?? "(Unknown user)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(userId ?? "???")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
            }
        }
        .padding(.leading, 2)
    }
}
