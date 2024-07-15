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
            Image(systemName: SystemImages.checkmarkShield.rawValue)
                .foregroundColor(Color.green)
        } else {
            Image(systemName: SystemImages.xmarkShield.rawValue)
                .foregroundColor(Color.red)
        }
    }
    
    var body: some View {
        HStack(alignment: .top) {
            UserAvatarView(user: user)
                .frame(width: 45, height: 45)
            
            VStack(alignment: .leading) {
                Text(user.displayName ?? user.userId.username)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    //.padding(1)

                Text(user.id)
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
                    //.padding(.leading, 1)
            }
        }
        /*
        .contextMenu {
            Button(action: {
                user.verify()
            }) {
                Label("Verify User", systemImage: SystemImages.checkmarkShield.rawValue))
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
