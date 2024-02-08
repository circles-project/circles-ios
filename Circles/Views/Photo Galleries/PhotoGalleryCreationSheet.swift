//  Copyright 2021 Kombucha Digital Privacy Systems LLC
//  Copyright 2022, 2023 FUTO Holdings Inc
//
//  PhotoGalleryCreationSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/12/21.
//

import SwiftUI
import PhotosUI
import Matrix

struct PhotoGalleryCreationSheet: View {
    //@ObservedObject var store: KSStore
    var container: ContainerRoom<GalleryRoom>
    @Environment(\.presentationMode) var presentation
    
    @State private var galleryName: String = ""
    @State private var avatarImage: UIImage? = nil

    @State var selectedItem: PhotosPickerItem?
    
    func create() async throws {
        let roomId = try await self.container.createChild(name: self.galleryName,
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
        }
        .font(.subheadline)

    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                buttonBar
                
                Text("New Photo Gallery")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                let frameWidth: CGFloat = 200
                let frameHeight: CGFloat = 120
                    
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let img = avatarImage {
                        ZStack {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: frameWidth, height: frameHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .background(RoundedRectangle(cornerRadius: 10)
                                            //.stroke(Color.gray, lineWidth: 2)
                                    .stroke(Color.gray)
                                    .foregroundColor(.background)
                                )
                                .padding()
                            
                            Text(galleryName)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 10)
                        }
                    } else {
                        Image(systemName: "camera.on.rectangle")
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .frame(width: frameWidth, height: frameHeight)
                            .background(RoundedRectangle(cornerRadius: 10)
                                        //.stroke(Color.gray, lineWidth: 2)
                                .stroke(Color.gray, style: StrokeStyle(lineWidth: 5, dash: [10, 10]))
                                .foregroundColor(.background)
                            )
                            .padding()
                    }
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        print("Handling a new item")
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data)
                        {
                            await MainActor.run {
                                self.avatarImage = img
                            }
                        }
                    }
                }
                
                TextField("Gallery name", text: $galleryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                Spacer()
                
                AsyncButton(action: {
                    try await create()
                }) {
                    Text("Create gallery \(galleryName)")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .disabled(galleryName.isEmpty)
                
                Spacer()
            }
            .padding()
            
        }
    }
}

/*
struct PhotoGalleryCreationSheet_Previews: PreviewProvider {
    static var previews: some View {
        PhotoGalleryCreationSheet()
    }
}
*/
