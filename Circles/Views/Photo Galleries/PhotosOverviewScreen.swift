//
//  PhotosScreen.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 11/3/20.
//

import SwiftUI

enum PhotosSheetType: String {
    case create
    case settings
}
extension PhotosSheetType: Identifiable {
    var id: String { rawValue }
}

struct PhotosOverviewScreen: View {
    //@ObservedObject var store: KSStore
    @ObservedObject var container: PhotoGalleriesContainer
    //@State var showCreationSheet = false
    
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
            ScrollView {
                ForEach(container.galleries) { gallery in
                    //Text("Found room \(room.roomId.string)")
                    NavigationLink(destination: PhotoGalleryView(gallery: gallery)) {
                        PhotoGalleryCard(room: gallery.room)
                        // FIXME Add a longPress gesture
                        //       for setting/changing the
                        //       avatar image for the gallery
                    }
                    .padding(1)
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
