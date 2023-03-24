//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PhotoGalleryCreationSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/12/21.
//

import SwiftUI
import Matrix

struct PhotoGalleryCreationSheet: View {
    //@ObservedObject var store: KSStore
    var container: ContainerRoom<GalleryRoom>
    @Environment(\.presentationMode) var presentation
    
    @State private var galleryName: String = ""
    @State private var avatarImage: UIImage? = nil
    
    func create() async throws {
        let roomId = try await self.container.createChildRoom(name: self.galleryName,
                                                              type: ROOM_TYPE_PHOTOS,
                                                              encrypted: true,
                                                              avatar: self.avatarImage)

        self.presentation.wrappedValue.dismiss()
    }
    
    var buttonBar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            })
            {
                Text("Cancel")
            }
            
            Spacer()
            
            AsyncButton(action: {
                try await create()
            }) {
                Text("Create")
                    .fontWeight(.bold)
            }
        }
        .font(.subheadline)

    }
    
    var body: some View {
        VStack {
            buttonBar
            
            Text("New Gallery")
                .font(.headline)
                .fontWeight(.bold)
            
            TextField("Gallery name", text: $galleryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Spacer()
        }
        .padding()

    }
}

/*
struct PhotoGalleryCreationSheet_Previews: PreviewProvider {
    static var previews: some View {
        PhotoGalleryCreationSheet()
    }
}
*/
