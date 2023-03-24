//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PhotoGalleryView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix

enum GallerySheetType: String {
    case new
    //case settings
    case avatar
}
extension GallerySheetType: Identifiable {
    var id: String { rawValue }
}

struct PhotoGalleryView: View {
    @ObservedObject var room: Matrix.Room
    //@ObservedObject var gallery: PhotoGallery
    @State var selectedMessage: Matrix.Message?
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
        }
        label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
    
    var timeline: some View {
        TimelineView(room: room, displayStyle: .photoGallery)
    }
    
    var body: some View {
        VStack {
            timeline
        }
        .navigationBarTitle(room.name ?? "Untitled gallery")
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
                        let _ = Task { try await room.sendImage(image: img) }
                    }
                }
            case .avatar:
                ImagePicker(selectedImage: self.$newAvatar, sourceType: .photoLibrary) { maybeImg in
                    if let img = maybeImg {
                        let _ = Task { try await room.setAvatarImage(image: img) }
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
