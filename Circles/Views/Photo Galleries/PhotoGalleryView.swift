//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PhotoGalleryView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI

enum GallerySheetType: String {
    case new
    //case settings
    case avatar
}
extension GallerySheetType: Identifiable {
    var id: String { rawValue }
}

struct PhotoGalleryView: View {
    //@ObservedObject var room: MatrixRoom
    @ObservedObject var gallery: PhotoGallery
    @Environment(\.presentationMode) var presentation

    @State var sheetType: GallerySheetType? = nil
    @State var newPhoto: UIImage?
    @State var newAvatar: UIImage?
    
    var toolbarMenu: some View {
        Menu {
            Button(action: {
                self.sheetType = .new
            }) {
                Label("Upload a new photo", systemImage: "photo.fill")
            }
            Button(action: {
                self.sheetType = .avatar
            }) {
                Label("New cover image", systemImage: "photo")
            }
            Button(action: {
                self.gallery.leave() { _ in }
                self.presentation.wrappedValue.dismiss()
            }) {
                Label("Remove this gallery", systemImage: "xmark.bin")
            }
        }
        label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
    
    var timeline: some View {
        TimelineView(room: gallery.room, displayStyle: .photoGallery)
    }
    
    var body: some View {
        VStack {
            timeline
        }
        .navigationBarTitle(gallery.room.displayName ?? "Untitled gallery")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                toolbarMenu
            }
        }
        .sheet(item: self.$sheetType) { st in
            switch(st) {
            case .new:
                ImagePicker(selectedImage: self.$newPhoto, sourceType: .photoLibrary) { maybeImg in
                    if let img = maybeImg {
                        gallery.room.postImage(image: img) { response in
                            switch(response) {
                            case .failure(let err):
                                break
                            case .success(let msg):
                                break
                            }
                        }
                    }
                }
            case .avatar:
                ImagePicker(selectedImage: self.$newAvatar, sourceType: .photoLibrary) { maybeImg in
                    if let img = maybeImg {
                        gallery.room.setAvatarImage(image: img) { response in
                            if response.isSuccess {
                                gallery.room.objectWillChange.send()
                            }
                        }
                    }
                }
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
