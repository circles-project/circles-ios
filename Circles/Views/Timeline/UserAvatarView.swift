//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ProfileImageView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix

struct UserAvatarView: View {
    @ObservedObject var user: Matrix.User
    @Environment(\.colorScheme) var colorScheme
    
    var defaultImageColor: Color {
        colorScheme == .dark
            ? Color.white
            : Color.black
    }
    
    var body: some View {
        if let avatar = user.avatar {
            BasicImage(uiImage: avatar)
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
        } else {
            ZStack {
                let color = Color.background.randomColor(from: user.userId.stringValue)
                
                Image("")
                    .resizable()
                    .background(color)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                
                let userIdCharacter = user.userId.stringValue.dropFirst().first?.uppercased()
                
                Text(String(user.displayName?.first?.uppercased() ?? userIdCharacter ?? ""))
                    .fontWeight(.bold)
                    .font(.title3)
                    .foregroundColor(.white)
                    .shadow(color: .gray, radius: 1)
            }
        }
    }
}
