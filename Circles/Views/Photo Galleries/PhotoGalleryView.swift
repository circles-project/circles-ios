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
    case share
}
extension GallerySheetType: Identifiable {
    var id: String { rawValue }
}

struct PhotoGalleryView: View {
    @ObservedObject var room: GalleryRoom
    var container: ContainerRoom<GalleryRoom>
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
    @State var showErrorAlert = false
    @State private var errorMessage = ""
    
    var toolbarMenu: some View {
        Menu {
            NavigationLink(destination: GallerySettingsView(room: room, container: container)) {
                Label("Settings", systemImage: "gearshape")
            }
            
            Button(action: { self.sheetType = .share }) {
                Label("Share", systemImage: "square.and.arrow.up")
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
    
    private var showErrorMessageView: some View {
        VStack {
            if errorMessage != "" {
                ToastView(titleMessage: errorMessage)
                Text("")
                    .onAppear {
                        errorMessage = ""
                    }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            showErrorMessageView
            if uploadItems.isEmpty {
                
                ZStack {

                    VStack {
                        if room.knockingMembers.count > 0 {
                            RoomKnockIndicator(room: room)
                        }
                        GalleryGridView(room: room)
                    }
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()

                            if room.iCanSendEvent(type: M_ROOM_MESSAGE) {
                                PhotosPicker(selection: $selectedItems) {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .padding()
                                }
                                .onChange(of: selectedItems) { newItems in
                                    CirclesApp.logger.debug("User picked \(newItems.count) new items")
                                    uploadItems.append(contentsOf: newItems)
                                    totalUploadItems += uploadItems.count
                                }
                            }
                        }
                    }
                    .onChange(of: avatarItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data)
                            {
                                do {
                                    try await room.setAvatarImage(image: img)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
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
                    case .share:
                        let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/gallery/\(room.roomId.stringValue)")
                        RoomShareSheet(room: self.room, url: url)
                    }
                }
                .photosPicker(isPresented: $showCoverImagePicker, selection: $avatarItem, matching: .images)
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Some items failed to upload"))
                }
            } else {
                PhotosUploadView(room: room, items: $uploadItems, total: $totalUploadItems, showAlert: $showErrorAlert)
                    .navigationBarTitle("Uploading...")
            }
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
