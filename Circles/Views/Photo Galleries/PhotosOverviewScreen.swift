//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
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
    var room: Matrix.Room?
    
    init(container: ContainerRoom<GalleryRoom>) {
        self.container = container
        self.room = container.rooms.first
    }
    
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
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    ForEach(container.rooms) { room in
                        //Text("Found room \(room.roomId.string)")
                        NavigationLink(destination: PhotoGalleryView(room: room)) {
                            PhotoGalleryCard(room: room)
                            // FIXME Add a longPress gesture
                            //       for setting/changing the
                            //       avatar image for the gallery
                        }
                        .padding(1)
                    }
                }
                
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
            .navigationBarTitle("Photo Galleries", displayMode: .inline)
            .sheet(item: $sheetType) { st in
                switch(st) {
                case .create:
                    PhotoGalleryCreationSheet(container: container)
                default:
                    Text("Coming soon")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    toolbarMenu
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
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
