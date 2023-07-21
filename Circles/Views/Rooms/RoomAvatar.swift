//
//  RoomAvatar.swift
//  Circles
//
//  Created by Charles Wright on 4/11/23.
//

import Foundation
import SwiftUI

import Matrix

struct RoomAvatar: View {
    @ObservedObject var room: Matrix.Room
    
    var body: some View {
        Image(uiImage: room.avatar ?? UIImage())
            .renderingMode(.original)
            .resizable()
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onAppear {
                // Fetch the avatar from the url
                room.updateAvatarImage()
            }
    }
}
