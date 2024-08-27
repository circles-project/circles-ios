//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//  Copyright 2022, 2023 FUTO Holdings Inc
//
//  PhotosScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix

enum PhotosSheetType: String {
    case create
    //case settings
    case scanQr
}
extension PhotosSheetType: Identifiable {
    var id: String { rawValue }
}

struct PhotosOverviewScreen: View {
    //@ObservedObject var store: KSStore
    @ObservedObject var container: ContainerRoom<GalleryRoom>
    //@State var selectedGallery: GalleryRoom?
    @Binding var selected: RoomId?
    //@State var showCreationSheet = false
    
    @State var showConfirmLeave = false
    @State var roomToLeave: GalleryRoom?
    
    @State private var sheetType: PhotosSheetType? = nil
    
    var toolbarMenu: some View {
        Menu {
            Button(action: { self.sheetType = .create }) {
                Label("New Gallery", systemImage: "plus")
            }
            
            Button(action: { self.sheetType = .scanQr }) {
                Label("Scan QR code", systemImage: "qrcode")
            }
        }
        label: {
            Label("More", systemImage: SystemImages.ellipsisCircle.rawValue)
        }
    }
    
    @ViewBuilder
    var baseLayer: some View {
        let invitations = container.session.invitations.values.filter { $0.type == ROOM_TYPE_PHOTOS }
        
        if !container.rooms.isEmpty || !invitations.isEmpty {
            VStack(alignment: .leading) {
                GalleryInvitationsIndicator(session: container.session, container: container)
                
                List(selection: $selected) {
                    let myGalleries = container.rooms.values
                        .filter { $0.creator == container.session.creds.userId }
                        .sorted(by: {$0.timestamp > $1.timestamp }) // Reverse chronological ordering
                    /*
                    Text("MY GALLERIES")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    */
                    Section("My Galleries") {
                        ForEach(myGalleries) { room in
                            //Text("Found room \(room.roomId.string)")
                            NavigationLink(value: room.roomId) {
                                PhotoGalleryCard(room: room)
                                // FIXME Add a longPress gesture
                                //       for setting/changing the
                                //       avatar image for the gallery
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    self.showConfirmLeave = true
                                    self.roomToLeave = room
                                }) {
                                    Label("Leave gallery", systemImage: SystemImages.xmarkBin.rawValue)
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    let sharedGalleries = container.rooms.values
                        .filter { $0.creator != container.session.creds.userId }
                        .sorted(by: {$0.timestamp > $1.timestamp }) // Reverse chronological ordering
                    /*
                    Text("SHARED GALLERIES")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    */
                    if !sharedGalleries.isEmpty {
                        Section("Shared Galleries") {
                            ForEach(sharedGalleries) { room in
                                //Text("Found room \(room.roomId.string)")
                                NavigationLink(value: room.roomId) {
                                    PhotoGalleryCard(room: room)
                                    // FIXME Add a longPress gesture
                                    //       for setting/changing the
                                    //       avatar image for the gallery
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive, action: {
                                        self.showConfirmLeave = true
                                        self.roomToLeave = room
                                    }) {
                                        Label("Leave gallery", systemImage: SystemImages.xmarkBin.rawValue)
                                    }
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.plain)
                .accentColor(.secondaryBackground)
            }
            //.padding()
        }
        else {
            Text("Create a photo gallery to get started")
        }
    }
    
    @ViewBuilder
    var overlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Menu {
                    Button(action: { self.sheetType = .create }) {
                        Label("Create gallery", systemImage: "plus.circle")
                    }
                    Button(action: { self.sheetType = .scanQr }) {
                        Label("Scan QR code", systemImage: "qrcode")
                    }
                }
                label: {
                    Image(systemName: SystemImages.plusCircleFill.rawValue)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    var master: some View {
        ZStack {
            baseLayer
            
            overlay
        }
        .navigationBarTitle("Photo Galleries", displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                toolbarMenu
            }
        }
        .refreshable {
            await MainActor.run {
                container.objectWillChange.send()
            }
        }
        .sheet(item: $sheetType) { st in
            switch(st) {
            case .create:
                PhotoGalleryCreationSheet(container: container)
                    .background(Color.greyCool200)
            case .scanQr:
                ScanQrCodeAndKnockSheet(session: container.session)
                    .background(Color.greyCool200)
            }
        }
        .confirmationDialog(Text("Confirm Leaving Gallery"),
                            isPresented: $showConfirmLeave,
                            actions: {
            if let room = self.roomToLeave {
                AsyncButton(role: .destructive, action: {
                    try await container.leaveChild(room.roomId)
                }) {
                    Text("Leave \(room.name ?? "this gallery")")
                }
            }
        })
    }
    
    var body: some View {
        NavigationSplitView {
            master
                .background(Color.greyCool200)
        } detail: {
            if let roomId = selected,
               let room = container.rooms[roomId]
            {
                PhotoGalleryView(room: room, container: container)
                    .background(Color.greyCool200)
            } else {
                Text("Create or select a photo gallery to view an album")
            }
        }
    }
}

/*
struct PhotosScreen_Previews: PreviewProvider {
    static var previews: some View {
        PhotosOverviewScreen(store: KSStore())
    }
}
*/
