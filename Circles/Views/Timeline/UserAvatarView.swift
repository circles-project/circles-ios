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
        } else {
            ZStack {
                let color = Color.background.randomColor(from: user.userId.stringValue)
                
                Image("")
                    .resizable()
                    .background(color)
                    .scaledToFit()
                
                let userIdCharacter = user.userId.stringValue.dropFirst().first?.uppercased()
                
                Text(String(user.displayName?.first?.uppercased() ?? userIdCharacter ?? "dmytro"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(defaultImageColor)
            }
        }
    }
}
