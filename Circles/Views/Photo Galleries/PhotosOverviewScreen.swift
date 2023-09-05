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
    case settings
}
extension PhotosSheetType: Identifiable {
    var id: String { rawValue }
}

struct PhotosOverviewScreen: View {
    //@ObservedObject var store: KSStore
    @ObservedObject var container: ContainerRoom<GalleryRoom>
    //@State var showCreationSheet = false
    
    @EnvironmentObject var matrix: Matrix.Session

    @State var showConfirmLeave = false
    @State var roomToLeave: GalleryRoom?
    @State private var sheetType: PhotosSheetType? = nil
    
    var toolbarMenu: some View {
        Menu {
            Button(action: {}) {
                Label("Settings", systemImage: "gearshape")
            }
            
            Button(action: {
                self.sheetType = .create
            }) {
                Label("New Gallery", systemImage: "plus")
            }

        }
        label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
    
    @ViewBuilder
    var baseLayer: some View {
        let invitations = matrix.invitations.values.filter { $0.type == ROOM_TYPE_PHOTOS }
        
        if !container.rooms.isEmpty || !invitations.isEmpty {
            ScrollView {
                VStack(alignment: .leading) {
                    if !invitations.isEmpty {
                        Text("INVITATIONS")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        NavigationLink(destination: GalleryInvitationsView(container: container)) {
                            Label("\(invitations.count) invitation(s) to shared photo galleries", systemImage: "envelope.open.fill")
                        }

                        .padding()
                    }
                    
                    Text("GALLERIES")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    ForEach(container.rooms) { room in
                        //Text("Found room \(room.roomId.string)")
                        NavigationLink(destination: PhotoGalleryView(room: room)) {
                            PhotoGalleryCard(room: room)
                            // FIXME Add a longPress gesture
                            //       for setting/changing the
                            //       avatar image for the gallery
                        }
                        .contextMenu {
                            Button(role: .destructive, action: {
                                self.showConfirmLeave = true
                                self.roomToLeave = room
                            }) {
                                Label("Leave gallery", systemImage: "xmark.bin")
                            }
                        }
                        //.padding(1)
                    }
                }
                .padding()
            }
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
                Button(action: {
                    self.sheetType = .create
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .padding()
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
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
            .sheet(item: $sheetType) { st in
                switch(st) {
                case .create:
                    PhotoGalleryCreationSheet(container: container)
                default:
                    Text("Coming soon")
                }
            }
            .confirmationDialog(Text("Confirm Leaving Gallery"),
                                isPresented: $showConfirmLeave,
                                actions: {
                                    if let room = self.roomToLeave {
                                        AsyncButton(role: .destructive, action: {
                                            try await container.leaveChildRoom(room.roomId)
                                        }) {
                                            Text("Leave \(room.name ?? "this gallery")")
                                        }
                                    }
                                }
            )
            //.navigationViewStyle(StackNavigationViewStyle())
            
            Text("Create or select a photo gallery to view an album")
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
