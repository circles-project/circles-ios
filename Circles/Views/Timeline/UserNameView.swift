//
//  UserNameView.swift
//  Circles
//
//  Created by Charles Wright on 10/15/23.
//

import SwiftUI
import Matrix

struct UserNameView: View {
    @ObservedObject var user: Matrix.User
    
    var body: some View {
        Text(user.displayName ?? user.userId.username)
            .onAppear {
                user.refreshProfile()
            }
    }
}
