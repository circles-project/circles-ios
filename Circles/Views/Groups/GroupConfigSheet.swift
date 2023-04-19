//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  GroupConfigSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/18/20.
//

import SwiftUI
import PhotosUI
import Matrix

struct GroupConfigSheet: View {
    @ObservedObject var room: Matrix.Room
    @Environment(\.presentationMode) var presentation

    @State var groupName: String = ""
    @State var groupTopic: String = ""
    
    @State var headerImage: UIImage? = nil
    //@State var showPicker = false
    @State var selectedItem: PhotosPickerItem?
    
    init(room: Matrix.Room) {
        self.room = room
        self.groupName = room.name ?? ""
        self.headerImage = room.avatar
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
                    .padding()
            }
        }
    }
    
    var image: Image {
        if let img = self.headerImage ?? room.avatar {
            return Image(uiImage: img)
        } else {
            //: Image(systemName: "photo")
            return Image(uiImage: UIImage())
        }
    }
    
    var body: some View {
        buttonbar

        NavigationView {
            Form {
                Section(header: Text("Cover Image")) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        //Label("Choose header picture", systemImage: "photo")
                        image
                            .resizable()
                            .scaledToFit()
                        //.frame(width: 240, height: 240, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data)
                            {
                                await MainActor.run {
                                    self.headerImage = img
                                }
                                try await room.setAvatarImage(image: img)
                            }
                        }
                    }
                }
                Section(header: Text("Group name")) {
                    TextField(room.name ?? "Name", text: $groupName)
                        .onSubmit {
                            Task {
                                try await room.setName(newName: groupName)
                                self.groupName = ""
                            }
                        }
                }
            }
            .navigationTitle(Text("Settings for group \(room.name ?? "")"))
            .padding()
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
