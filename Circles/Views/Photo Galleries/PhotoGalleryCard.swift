//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PhotoGalleryCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI

struct PhotoGalleryCard: View {
    @ObservedObject var room: MatrixRoom
    
    var avatar: Image {
        room.avatarImage != nil
            ? Image(uiImage: room.avatarImage!)
            : Image(systemName: "photo")
    }
    
    var body: some View {
        ZStack {
            
            avatar
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 6))
    
            Text(room.displayName ?? room.id)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 3)
        }
    }
}

/*
struct PhotoGalleryCard_Previews: PreviewProvider {
    static var previews: some View {
        PhotoGalleryCard()
    }
}
 */
