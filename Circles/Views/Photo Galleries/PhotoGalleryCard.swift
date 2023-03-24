//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PhotoGalleryCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix

struct PhotoGalleryCard: View {
    @ObservedObject var room: Matrix.Room
    
    var avatar: Image {
        room.avatar != nil
            ? Image(uiImage: room.avatar!)
            : Image(systemName: "photo")
    }
    
    var body: some View {
        ZStack {
            
            avatar
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 6))
    
            Text(room.name ?? room.id)
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
