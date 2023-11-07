//
//  SimpleCircleAvatar.swift
//  Circles
//
//  Created by Charles Wright on 11/7/23.
//

import SwiftUI
import Matrix

struct SimpleCircleAvatar: View {
    @ObservedObject var space: CircleSpace
    
    var body: some View {
        Image(uiImage: space.wall?.avatar ?? space.avatar ?? UIImage())
            .resizable()
            .scaledToFill()
            .clipShape(Circle())
            .onAppear {
                space.wall?.updateAvatarImage()
            }
    }
}

