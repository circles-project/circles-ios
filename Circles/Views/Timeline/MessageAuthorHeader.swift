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
    
    @ViewBuilder
    var shield: some View {
        if user.isVerified {
            Image(systemName: "checkmark.shield")
                .foregroundColor(Color.green)
        } else {
            Image(systemName: "xmark.shield")
                .foregroundColor(Color.red)
        }
    }
    
    var body: some View {
        HStack(alignment: .top) {
            
            //profileImage
            UserAvatarView(user: user)
                //.resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                //.padding(3)

            
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text(user.displayName ?? user.userId.username)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .padding(1)

                    Text(user.id)
                        .font(.headline)
                        .foregroundColor(Color.gray)
                        .lineLimit(1)
                        .padding(.leading, 1)

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
        //.padding(.leading, 2)
        .onAppear {
            if user.avatarUrl == nil || user.displayName == nil {
                user.refreshProfile()
            }
            if user.avatar == nil && user.avatarUrl != nil {
                user.fetchAvatarImage()
            }
        }
    }
}
