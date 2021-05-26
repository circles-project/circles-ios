//
//  PhotoGalleryCreationSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/12/21.
//

import SwiftUI

struct PhotoGalleryCreationSheet: View {
    //@ObservedObject var store: KSStore
    @ObservedObject var container: PhotoGalleriesContainer
    @Environment(\.presentationMode) var presentation
    
    @State private var galleryName: String = ""
    @State private var avatarImage: UIImage? = nil
    
    func create() {
        let dgroup = DispatchGroup()
        var errors: Error? = nil
        
        if galleryName.isEmpty {
            return
        }
        
        dgroup.enter()
        container.create(name: self.galleryName) { response1 in
            switch(response1) {
            case .failure(let err):
                let msg = "Failed to create room \(self.galleryName)"
                errors = errors ?? KSError(message: msg)
                print(msg)
                dgroup.leave()
            case .success(let newGallery):
                let room = newGallery.room
                if let image = self.avatarImage {
                    room.setAvatarImage(image: image) { response2 in
                        switch(response2) {
                        case .failure(let err):
                            let msg = "Failed to set avatar image for gallery [\(self.galleryName)]"
                            errors = errors ?? KSError(message: msg)
                            print(msg)
                        case .success:
                            // Nothing else to do
                            break
                        }
                        dgroup.leave()
                    }
                }
                else {
                    dgroup.leave()
                }
            }
        }
        
        dgroup.notify(queue: .main) {
            if errors == nil {
                self.presentation.wrappedValue.dismiss()
            }
        }
    }
    
    var buttonBar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            })
            {
                Text("Cancel")
            }
            
            Spacer()
            
            Button(action: {
                create()
            }) {
                Text("Create")
                    .fontWeight(.bold)
            }
        }
        .font(.subheadline)

    }
    
    var body: some View {
        VStack {
            buttonBar
            
            Text("New Gallery")
                .font(.headline)
                .fontWeight(.bold)
            
            TextField("Gallery name", text: $galleryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Spacer()
        }
        .padding()

    }
}

/*
struct PhotoGalleryCreationSheet_Previews: PreviewProvider {
    static var previews: some View {
        PhotoGalleryCreationSheet()
    }
}
*/
