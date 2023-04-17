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
    @State var showPicker: Bool = false
    @State var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
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
        }
        .font(.subheadline)

    }
    
    var body: some View {
        GeometryReader { geometry in
            let size: CGFloat = geometry.size.width > 600 ? 500 : 300
            VStack {
                buttonBar
                
                Text("New Photo Gallery")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Menu {
                    Button(action: {
                        self.sourceType = .photoLibrary
                        self.showPicker = true
                    }) {
                        Label("Cover image from device", systemImage: "photo")
                    }
                    
                    Button(action: {
                        self.sourceType = .camera
                        self.showPicker = true
                    }) {
                        Label("Take new cover image", systemImage: "camera")
                    }
                } label: {
                    if let img = avatarImage {
                        ZStack {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: size, height: size)
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
                            .frame(width: size, height: size)
                            .background(RoundedRectangle(cornerRadius: 10)
                                        //.stroke(Color.gray, lineWidth: 2)
                                .stroke(Color.gray, style: StrokeStyle(lineWidth: 5, dash: [10, 10]))
                                .foregroundColor(.background)
                            )
                            .padding()
                    }
                }
                .sheet(isPresented: $showPicker) {
                    ImagePicker(selectedImage: $avatarImage, sourceType: self.sourceType)
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
