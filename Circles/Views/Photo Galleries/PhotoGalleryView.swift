//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//  Copyright 2022, 2023 FUTO Holdings Inc
//
//  PhotoGalleryView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import PhotosUI
import Matrix

enum GallerySheetType: String {
    //case new
    //case settings
    //case avatar
    case invite
}
extension GallerySheetType: Identifiable {
    var id: String { rawValue }
}

struct PhotoGalleryView: View {
    @ObservedObject var room: Matrix.Room
    //@ObservedObject var gallery: PhotoGallery
    @State var selectedMessage: Matrix.Message?
    @State var selectedItems: [PhotosPickerItem] = []
    @State var avatarItem: PhotosPickerItem?
    @Environment(\.presentationMode) var presentation

    @State var sheetType: GallerySheetType? = nil
    //@State var newPhoto: UIImage?
    //@State var newAvatar: UIImage?
    @State var showCoverImagePicker: Bool = false
    
    @State var uploadItems: [PhotosPickerItem] = []
    @State var totalUploadItems: Int = 0
    
    var toolbarMenu: some View {
        Menu {
            if room.iCanChangeState(type: M_ROOM_AVATAR) {
                Button(action: {
                    self.showCoverImagePicker = true
                }) {
                    Label("New cover image", systemImage: "photo")
                }
            }
            
            if room.iCanInvite {
                Button(action: {
                    self.sheetType = .invite
                }) {
                    Label("Invite", systemImage: "person.2.circle")
                }
            }
        }
        label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
    
    var body: some View {
        if uploadItems.isEmpty {
            
            ZStack {
                //TimelineView<PhotoCard>(room: room)
                GalleryGridView(room: room)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        /*
                         Button(action: {
                         self.sheetType = .new
                         }) {
                         Image(systemName: "plus.circle.fill")
                         .resizable()
                         .scaledToFill()
                         .frame(width: 50, height: 50)
                         .padding()
                         }
                         */
                        PhotosPicker(selection: $selectedItems, matching: .images) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .padding()
                        }
                        .onChange(of: selectedItems) { newItems in
                            /*
                            Task {
                                for newItem in newItems {
                                    if let data = try? await newItem.loadTransferable(type: Data.self),
                                       let img = UIImage(data: data) {
                                        try await room.sendImage(image: img)
                                    }
                                }
                            }
                            */
                            uploadItems.append(contentsOf: newItems)
                            totalUploadItems += uploadItems.count
                        }
                    }
                }
                .onChange(of: avatarItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data)
                        {
                            try await room.setAvatarImage(image: img)
                        }
                    }
                }
            }
            .navigationBarTitle(room.name ?? "Untitled gallery")
            .toolbar {
                if room.iCanChangeState(type: M_ROOM_AVATAR) || room.iCanInvite {
                    ToolbarItemGroup(placement: .automatic) {
                        toolbarMenu
                    }
                }
            }
            .sheet(item: self.$sheetType) { st in
                switch(st) {
                case .invite:
                    RoomInviteSheet(room: self.room)
                }
            }
            .photosPicker(isPresented: $showCoverImagePicker, selection: $avatarItem, matching: .images)
        } else {
            PhotosUploadView(room: room, items: $uploadItems, total: $totalUploadItems)
        }
    }
}

/*
struct PhotoGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoGalleryView()
    }
}
 */
