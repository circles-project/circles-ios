//
//  PhotoGalleryCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI

struct PhotoGalleryCard: View {
    @ObservedObject var room: MatrixRoom
    
    // FIXME Crap these are only MXEvents...
    // Need an ObservableObject to get updates from SwiftUI
    //var previewEvents: ArraySlice<MXEvent>
    //var previewMessage: MatrixMessage?
    
    /*
    init(room: MatrixRoom) {
        let previewEvent = room.messages
            .filter { msg in
                switch(msg.content) {
                case .image( _):
                    return true
                default:
                    return false
                }
            }
            //.shuffled()
            //.prefix(4)
            .randomElement()
        self.room = room
        self.previewMessage = previewEvent
    }
    */
    
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
