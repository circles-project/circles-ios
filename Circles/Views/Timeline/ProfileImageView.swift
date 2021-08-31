//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ProfileImageView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI

struct ProfileImageView: View {
    @ObservedObject var user: MatrixUser
    
    var image: Image {
        Image(uiImage: user.avatarImage ?? UIImage(systemName: "person.fill")!)
    }
    
    var body: some View {
        image
        .resizable()
    }
}
