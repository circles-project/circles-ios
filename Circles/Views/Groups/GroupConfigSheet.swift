//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  GroupConfigSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/18/20.
//

import SwiftUI

struct GroupConfigSheet: View {
    @ObservedObject var room: MatrixRoom
    @Environment(\.presentationMode) var presentation

    @State var groupName: String = ""
    @State var groupTopic: String = ""
    
    @State var headerImage: UIImage? = nil
    @State var showPicker = false
    
    var picker: some View {
        EmbeddedImagePicker(selectedImage: $headerImage, isEnabled: $showPicker) { image in
            room.setAvatarImage(image: image)
        }
    }
    
    var buttonbar: some View {
        HStack {
            Spacer()
            
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            })
            {
                Text("Done")
                    .fontWeight(.bold)
            }
        }
    }
    
    var image: Image {
        (self.headerImage != nil)
            ? Image(uiImage: self.headerImage!)
            //: Image(systemName: "photo")
            : Image(uiImage: UIImage())
    }
    
    var dialog: some View {
        VStack {
            buttonbar
            
            Text("Configure Group")
                .font(.headline)
                .fontWeight(.bold)
            
            GroupHeader(room: room) { }
                .padding(.bottom)
            
            //Spacer()
            
            HStack {
                TextField("Group name", text: $groupName)
                
                Button(action: {
                    room.setDisplayName(self.groupName) { response in
                        self.groupName = ""
                    }
                }) {
                    Label("Set", systemImage: "square.and.arrow.up")
                }
            }
            
            HStack {
                TextField("Status message", text: $groupTopic)
                
                Button(action: {
                    room.setTopic(topic: self.groupTopic) { response in
                        self.groupTopic = ""
                    }
                }) {
                    Label("Set", systemImage: "square.and.arrow.up")
                }
                
            }
            
            image
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Button(action: {self.showPicker = true}) {
                Label("Choose header picture", systemImage: "photo")
            }
            
            Spacer()
            
        }
        .padding()
    }
    
    var body: some View {
        VStack {
            if self.showPicker {
                picker
            }
            else {
                dialog
            }
        }
    }
}

/*
struct GroupConfigSheet_Previews: PreviewProvider {
    static var previews: some View {
        GroupConfigSheet()
    }
}
*/
