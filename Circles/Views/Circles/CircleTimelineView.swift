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
    //case settings
    //case followers
    //case following
    case invite
    //case photo
    case share
}
extension CircleSheetType: Identifiable {
    var id: String { rawValue }
}

struct CircleTimelineView: View {
    @ObservedObject var space: CircleSpace
    @Environment(\.presentationMode) var presentation
    
    //@State var showComposer = false
    @State var sheetType: CircleSheetType? = nil
    @State var showPhotosPicker: Bool = false
    @State var selectedItem: PhotosPickerItem?
    //@State var image: UIImage?
    @State private var errorMessage = ""
    
    var toolbarMenu: some View {
        Menu {

            NavigationLink(destination: CircleSettingsView(space: space) ){
                Label("Settings", systemImage: "gearshape.fill")
            }
            
            Button(action: {self.sheetType = .invite}) {
                Label("Invite Followers", systemImage: "person.crop.circle.badge.plus")
            }
            
            Button(action: {self.sheetType = .share}) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        label: {
            Label("Settings", systemImage: "gearshape")
        }
    }

    var stupidSwiftUiTrick: Int {
        print("DEBUGUI\tStreamTimeline rendering for Circle \(space.roomId)")
        return 0
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
            ZStack {
                showErrorMessageView
                
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
                                do {
                                    try await room.setAvatarImage(image: img)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                    .sheet(item: $sheetType) { st in
                        switch(st) {

                        case .invite:
                            RoomInviteSheet(room: space.wall!)
                            
                        case .share:
                            if let wall = space.wall,
                               let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/timeline/\(wall.roomId.stringValue)")
                            {
                                RoomShareSheet(room: wall, url: url)
                            } else {
                                Text("Error: Unable to generate QR code")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                
                if let wall = space.wall {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            NavigationLink(destination: PostComposer(room: wall).navigationTitle("New Post")) {
                                Image(systemName: "plus.bubble.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .padding()
                            }
                        }
                    }
                }
            }
        }
    }
}

