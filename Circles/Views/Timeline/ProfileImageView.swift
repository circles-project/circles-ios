//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ProfileImageView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix

struct ProfileImageView: View {
    @ObservedObject var user: Matrix.User
    @Environment(\.colorScheme) var colorScheme
    
    var defaultImageColor: Color {
        colorScheme == .dark
            ? Color.white
            : Color.black
    }
    
    var body: some View {
        if let avatar = user.avatar {
            Image(uiImage: avatar)
                .resizable()
                .scaledToFit()
        }
        else {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(defaultImageColor)
        }
    }
}
