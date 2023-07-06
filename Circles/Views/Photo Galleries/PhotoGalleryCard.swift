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
    @AppStorage("debugMode") var debugMode: Bool = false
    
    var avatar: Image {
        
        if let avatar = room.avatar {
            return Image(uiImage: avatar)
        } else {
            return Image(systemName: "photo")
        }
        /*
        room.avatar != nil
            ? Image(uiImage: room.avatar!)
            : Image(systemName: "photo")
        */
    }
    
    var timestamp: some View {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        return Text("\(date, formatter: formatter)")
    }
    
    var body: some View {
        ZStack {
            
            RoomAvatar(room: room)
                /*
                .onAppear {
                    // Dirty nasty hack to test how/when SwiftUI is updating our Views
                    Task {
                        while true {
                            let sec = Int.random(in: 10...30)
                            try await Task.sleep(for: .seconds(sec))
                            let imageName = ["diamond.fill", "circle.fill", "square.fill", "seal.fill", "shield.fill"].randomElement()!
                            let newImage = UIImage(systemName: imageName)
                            await MainActor.run {
                                print("Setting avatar for room \(room.roomId)")
                                room.avatar = newImage
                            }
                        }
                    }
                }
                */
    
            VStack {
                Text(room.name ?? "")
                    .font(.title)
                    .fontWeight(.bold)

                if debugMode {
                    Text(room.roomId.description)
                        .font(.subheadline)
                    timestamp
                        .font(.subheadline)
                    //Text(room.avatarUrl?.mediaId ?? "(none)")
                    //    .font(.subheadline)
                }

            }
            .foregroundColor(.white)
            .shadow(color: .black, radius: 5)
        }

        .contextMenu {
            Button(action: {
                room.objectWillChange.send()
            }) {
                Text("Update")
            }
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
