//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CloudImagePicker.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/12/21.
//

import SwiftUI
import Matrix

struct GalleryThumbnail: View {
    @ObservedObject var message: Matrix.Message
    
    var body: some View {
        VStack(alignment: .center) {
            if let img = message.thumbnail {
                Image(uiImage: img)
                    .resizable()
                    //.scaledToFill()
                    //.clipShape(RoundedRectangle(cornerRadius: 10))
                    //.frame(width: 100, height: 100)
            }
            else {
                ProgressView()
                    .scaleEffect(2.0)
                    //.frame(width: 100, height: 100)

            }
            /*
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.blue)
            */
        }
        //.frame(width: 90, height: 90)
        //.border(Color.blue, width: 1)
        //.padding()
        .onAppear {
            if message.thumbnail == nil,
               let content = message.content as? Matrix.MessageContent,
               content.thumbnail_url != nil || content.thumbnail_file != nil
            {
                let _ = Task {
                    try await message.fetchThumbnail()
                }
            }
        }
    }
}

struct GalleryPicker: View {
    @ObservedObject var room: Matrix.Room
    @State var loading = false
    @State var finishing = false
    
    var completion: (Matrix.mImageContent, UIImage) -> Void = { _,_ in }
    
    func downloadImageFromMessage(message: Matrix.Message) async throws {
        // Download the image
        guard let content = message.content as? Matrix.mImageContent
        else {
            // FIXME: Set error message
            return
        }
        
        await MainActor.run {
            self.finishing = true
        }
        
        if let file = content.file {
            guard let data = try? await message.room.session.downloadAndDecryptData(file),
                  let img = UIImage(data: data)
            else {
                // FIXME: Set error message
                return
            }
            completion(content, img)
            return
        }

        if let mxc = content.url {
            guard let data = try? await message.room.session.downloadData(mxc: mxc),
                  let img = UIImage(data: data)
            else {
                // FIXME: Set error message
                return
            }
            completion(content, img)
            return
        }
        
        // Looks like we failed to get the image :(
        // FIXME: Set error message
        await MainActor.run {
            self.finishing = false
        }
        return
    }
    
    var body: some View {
        
        let messages = room.timeline.values.filter { (message) in
            message.relatedEventId == nil && message.type == M_ROOM_MESSAGE
        }.sorted(by: {$0.timestamp > $1.timestamp})
        
        ZStack {
            ScrollView {
                
                let columns = [
                    GridItem(.adaptive(minimum: 100, maximum: 100)),
                ]
                
                LazyVGrid(columns: columns, alignment: .center) {
                    ForEach(messages) { message in
                        AsyncButton(action: {
                            try await self.downloadImageFromMessage(message: message)
                        }) {
                            GalleryThumbnail(message: message)
                        }
                        //.border(Color.red, width: 1)
                        .frame(width: 100, height: 100)
                        //.border(Color.green, width: 1)
                        
                    }
                }.padding(.all, 10)
                
                HStack(alignment: .bottom) {
                    Spacer()
                    if loading {
                        ProgressView("Loading...")
                        //.progressViewStyle(LinearProgressViewStyle())
                    }
                    else if room.canPaginate {
                        AsyncButton(action: {
                            self.loading = true
                            try await room.paginate()
                            self.loading = false
                        }) {
                            Text("Load More")
                        }
                        .onAppear {
                            // It's a magic self-clicking button.
                            // If it ever appears, we basically automatically click it for the user
                            self.loading = true
                            let _ = Task {
                                try await room.paginate()
                                self.loading = false
                            }
                        }
                    }
                    Spacer()
                }
            }
            
            if finishing {
                ProgressView()
                    .scaleEffect(4.0)
            }
        }
    }
}

struct CloudImagePicker: View {
    @ObservedObject var galleries: ContainerRoom<GalleryRoom>
    
    @Binding var selected: Matrix.mImageContent?
    @Environment(\.presentationMode) private var presentation
    
    @State var selectedRoom: Matrix.Room? = nil
    var completion: ((Matrix.mImageContent, UIImage) -> Void)? = nil
    
    struct GalleryCard: View {
        @ObservedObject var room: Matrix.Room
        var body: some View {
            ZStack {
                if let img = room.avatar {
                    Image(uiImage: img)
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                } else {
                    ProgressView()
                        .scaleEffect(4.0)
                        .foregroundColor(.gray)
                        .onAppear {
                            room.updateAvatarImage()
                        }
                }
                
                Text(room.name ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 10)
            }
        }
    }
    
    var topbar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .font(.subheadline)
            }
            
            Spacer()
            
        }
    }
    
    var roomList: some View {
        ScrollView {
            let columns = [
                GridItem(.adaptive(minimum: 150, maximum: 300)),
                GridItem(.adaptive(minimum: 150, maximum: 300)),
            ]
            LazyVGrid(columns: columns, alignment: .center) {
                let rooms = galleries.rooms.values.sorted { $0.timestamp < $1.timestamp }
                ForEach(rooms) { room in
                    Button(action: {
                        self.selectedRoom = room
                    }) {
                        //GalleryCard(room: room)
                        
                        RoomAvatar(room: room, avatarText: .roomName)
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    //.frame(width: 300, height: 225)
                }
            }
        }
    }
    
    
    
    var body: some View {
        VStack {
            if let room = self.selectedRoom {

                HStack {
                    Text(room.name ?? "(Untitled gallery)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        self.selectedRoom = nil
                    }) {
                        Text("Back")
                    }
                }
                
                GalleryPicker(room: room, completion: { content, image in
                    print("Setting selected to m.image content")
                    self.selected = content
                    if let handler = self.completion {
                        handler(content, image)
                    }
                    self.presentation.wrappedValue.dismiss()
                })
                
            }
            else {
                
                topbar
                
                Divider()
            
                HStack(alignment: .bottom) {
                    Text("My Galleries")
                        .font(.title2)
                        .fontWeight(.bold)
                
                    Spacer()
                
                    Button(action: {
                        // FIXME: Implement this?
                    }) {
                        Text("See All")
                    }
                }
            
                roomList
            }

        }
        .padding()
        
    }
}

/*
struct CloudImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        CloudImagePicker()
    }
}
*/
