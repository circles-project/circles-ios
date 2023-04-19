//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleTimelineScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/17/20.
//

import SwiftUI
import PhotosUI

enum CircleSheetType: String {
    case settings
    case followers
    case following
    case invite
    //case photo
    case composer
}
extension CircleSheetType: Identifiable {
    var id: String { rawValue }
}

struct CircleTimelineScreen: View {
    @ObservedObject var space: CircleSpace
    @Environment(\.presentationMode) var presentation
    
    //@State var showComposer = false
    @State var sheetType: CircleSheetType? = nil
    @State var showPhotosPicker: Bool = false
    @State var selectedItem: PhotosPickerItem?
    //@State var image: UIImage?
    
    var toolbarMenu: some View {
        Menu {
            Menu {
                
                Button(action: {
                    self.showPhotosPicker = true
                }) {
                    Label("New Cover Photo", systemImage: "photo")
                }
            }
            label: {
                Label("Settings", systemImage: "gearshape")
            }
            
            Menu {
                Button(action: {self.sheetType = .followers}) {
                    Label("My followers", systemImage: "person.2.circle")
                }
                Button(action: {self.sheetType = .following}) {
                    Label("People I'm following", systemImage: "person.2.circle.fill")
                }
            }
            label: {
                Label("Connections", systemImage: "person.2.circle")
            }
            
            Button(action: {self.sheetType = .invite}) {
                Label("Invite Followers", systemImage: "person.crop.circle.badge.plus")
            }
            
            Button(action: {self.sheetType = .composer}) {
                Label("Post a New Message", systemImage: "plus.bubble")
            }
        }
        label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }

    var stupidSwiftUiTrick: Int {
        print("DEBUGUI\tStreamTimeline rendering for Circle \(space.roomId)")
        return 0
    }
    
    var body: some View {
        //VStack {
            /*
            composer
                .layoutPriority(1)
            */
        let foo = self.stupidSwiftUiTrick
            
            CircleTimeline(space: space)
                .navigationBarTitle(space.name ?? "Circle", displayMode: .inline)
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        toolbarMenu
                    }
                }
                .onAppear {
                    print("DEBUGUI\tStreamTimeline appeared for Circle \(space.roomId)")
                }
                .onDisappear {
                    print("DEBUGUI\tStreamTimeline disappeared for Circle \(space.roomId)")
                }
                .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let room = self.space.wall,
                           let data = try? await newItem?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data)
                        {
                            try await room.setAvatarImage(image: img)
                        }
                    }
                }
                .sheet(item: $sheetType) { st in
                    switch(st) {
                    case .invite:
                        RoomInviteSheet(room: space.wall!)
                    case .followers:
                        RoomMembersSheet(room: space.wall!)
                    case .following:
                        CircleConnectionsSheet(space: space)
                    /*
                    case .photo:
                        ImagePicker(selectedImage: self.$image, sourceType: .photoLibrary, allowEditing: false) { maybeImage in
                            guard let room = self.space.wall,
                                  let newImage = maybeImage
                            else {
                                print("CIRCLEIMAGE\tEither we couldn't find a room where we can post, or the user didn't pick an image")
                                return
                            }
                            let _ = Task {
                                try await room.setAvatarImage(image: newImage)
                            }
                        }
                    */
                    case .composer:
                        MessageComposerSheet(room: space.wall!)
                    default:
                        Text("Coming soon!")
                    }
                }
        //}
    }
}

/*
struct CircleTimelineScreen_Previews: PreviewProvider {
    static var previews: some View {
        CircleTimelineScreen()
    }
}
*/
