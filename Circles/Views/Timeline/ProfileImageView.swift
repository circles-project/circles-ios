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
        user.avatarImage != nil
            ? Image(uiImage: user.avatarImage!)
            : Image(systemName: "person.fill")
    }
    
    var body: some View {
        image
        .resizable()
    }
}
