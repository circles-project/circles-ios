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
    
    var body: some View {
        HStack(alignment: .center) {
            UserAvatarView(user: user)
                .frame(width: 45, height: 45)
            
            Text(user.displayName ?? user.userId.username)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
                //.padding(1)
        }
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
