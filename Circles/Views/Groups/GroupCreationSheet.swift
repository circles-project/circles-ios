//
//  ChannelCreationSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/14/20.
//

import SwiftUI
import MatrixSDK

struct GroupCreationSheet: View {
    //@ObservedObject var store: KSStore
    @ObservedObject var groups: GroupsContainer
    @Environment(\.presentationMode) var presentation
    
    @State var groupName: String = ""
    @State var groupTopic: String = ""
    
    @State var newestUserId: String = ""
    @State var newUserIds: [String] = []
    
    @State var headerImage: UIImage? = nil
    @State var showPicker = false
    
    var picker: some View {
        EmbeddedImagePicker(selectedImage: $headerImage, isEnabled: $showPicker)
    }
    
    var buttonbar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            })
            {
                Text("Cancel")
            }
            
            Spacer()
            
            Button(action: {
                groups.create(name: self.groupName) { response in
                    switch(response) {
                    case .failure(let error):
                        print("Failed to create new group [\(self.groupName)]: \(error)")
                    case .success(let newGroup):
                        let room = newGroup.room
                        let dgroup = DispatchGroup()
                        var errors: Error? = nil
                        
                        if !self.groupTopic.isEmpty {
                            dgroup.enter()
                            room.setTopic(topic: self.groupTopic) { response in
                                if response.isFailure {
                                    errors = errors ?? KSError(message: "Failed to set topic")
                                }
                                dgroup.leave()
                            }
                        }
                        if let img = self.headerImage {
                            dgroup.enter()
                            room.setAvatarImage(image: img) { response in
                                if response.isFailure {
                                    errors = errors ?? KSError(message: "Failed to set avatar image")
                                }
                                dgroup.leave()
                            }
                        }
                        for userId in self.newUserIds {
                            dgroup.enter()
                            room.invite(userId: userId) { response in
                                if response.isFailure {
                                    errors = errors ?? KSError(message: "Failed to invite \(userId)")
                                }
                                dgroup.leave()
                            }
                        }
                    
                        dgroup.notify(queue: .main) {
                            if errors == nil {
                                self.presentation.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            })
            {
                Text("Create")
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
    
    var creationSheet: some View {
        VStack {
            buttonbar
            
            Text("New Group")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                /*
                Text("Name:")
                    .fontWeight(.bold)
                */
                TextField("Group name", text: $groupName)
            }
            
            HStack {
                /*
                Text("Initial Status:")
                    .fontWeight(.bold)
                */
                TextField("Initial status message", text: $groupTopic)
            }
            
            ZStack {
                image
                    .resizable()
                    .scaledToFit()
                if self.headerImage == nil {
                    Text("Header image")
                        .foregroundColor(Color.gray)
                }
                else {
                    VStack {
                        Text(self.groupName)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.white)
                            .shadow(color: Color.black, radius: 3.0)
                            .padding()

                        Text(self.groupTopic)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.white)
                            .shadow(color: Color.black, radius: 3.0)
                            .padding(.horizontal)
                    }
                }
            }
            .onLongPressGesture {
                self.showPicker = true
            }
            
            Spacer()
            
            Text("Users to invite:")
                .fontWeight(.bold)
            HStack {
                TextField("User ID", text: $newestUserId)
                    .autocapitalization(.none)
                
                Button(action: {
                    if let canonicalUserId = groups.matrix.canonicalizeUserId(userId: newestUserId) {
                        self.newUserIds.append(canonicalUserId)
                    }
                    self.newestUserId = ""
                }) {
                    Text("Add")
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading) {
                /*
                if newUserIds.isEmpty {
                    Text("(none)")
                }
                else {
*/
                    List {
                        ForEach(newUserIds, id: \.self) { userId in
                            if let user = groups.matrix.getUser(userId: userId) {
                                MessageAuthorHeader(user: user)
                            }
                            else {
                                //Text(userId)
                                DummyMessageAuthorHeader(userId: userId)
                            }
                        }
                        .onDelete(perform: { indexSet in
                            self.newUserIds.remove(atOffsets: indexSet)
                        })
                    }
                //}
            }
            .padding(.leading)
                
            
        }
        .padding()
    }
    
    var body: some View {
        if showPicker {
            picker
        }
        else {
            creationSheet
        }
    }
}

/*
struct ChannelCreationSheet_Previews: PreviewProvider {
    static var previews: some View {
        ChannelCreationSheet()
    }
}
*/
