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
    
    @State var defaultPowerLevel = PowerLevel(power: 0)

    @State var selectedItem: PhotosPickerItem?
    
    @FocusState var inputFocused
    
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
        VStack(spacing: 10) {
            buttonBar
            let frameWidth: CGFloat = 300
            let frameHeight: CGFloat = 200
                
            ZStack {
                if let img = avatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: frameWidth, height: frameHeight)
                } else {
                    Color.gray
                        .frame(width: frameWidth, height: frameHeight)
                }
                    
                Text(galleryName)
                    .lineLimit(2)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .bottomTrailing) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
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
                .textInputAutocapitalization(.words)
                .focused($inputFocused)
                .frame(maxWidth: 350)
                .onAppear {
                    self.inputFocused = true
                }
            
            HStack {
                Text("Default user role")
                Spacer()
                Picker("User permissions", selection: $defaultPowerLevel) {
                    ForEach(CIRCLES_POWER_LEVELS) { level in
                        Text(level.description)
                            .tag(level)
                    }
                }
            }
            .frame(width: 300)

            Spacer()
            
            AsyncButton(action: {
                try await create()
            }) {
                Text("Create gallery \(galleryName)")
            }
            .buttonStyle(BigBlueButtonStyle())
            .disabled(galleryName.isEmpty)
            
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
