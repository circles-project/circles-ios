//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ChannelCreationSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/14/20.
//

import SwiftUI
import Matrix

struct GroupCreationSheet: View {
    //@ObservedObject var store: KSStore
    @ObservedObject var groups: ContainerRoom<GroupRoom>
    @Environment(\.presentationMode) var presentation
    
    @State var groupName: String = ""
    @State var groupTopic: String = ""
    
    @State var newestUserId: String = ""
    @State var users: [Matrix.User] = []
    
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
            
            AsyncButton(action: {
                
                guard let roomId = try? await groups.createChildRoom(name: self.groupName,
                                                                     type: ROOM_TYPE_GROUP,
                                                                     encrypted: true,
                                                                     avatar: self.headerImage),
                      let room = try await groups.session.getRoom(roomId: roomId)
                else {
                    // Set error message
                    return
                }
                
                if !self.groupTopic.isEmpty {
                    do {
                        try await room.setTopic(newTopic: self.groupTopic)
                    } catch {
                        // set error message
                        return
                    }
                }
                
                for user in self.users {
                    do {
                        try await room.invite(userId: user.userId)
                    } catch {
                        // set error message
                        return
                    }
                }
                
                self.presentation.wrappedValue.dismiss()

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
                
                AsyncButton(action: {
                    guard let userId = UserId(newestUserId)
                    else {
                        self.newestUserId = ""
                        // FIXME: Set error message
                        return
                    }
                    let user = groups.session.getUser(userId: userId)
                    self.users.append(user)
                    self.newestUserId = ""
                }) {
                    Text("Add")
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading) {

                List($users, editActions: .delete) { $user in
                    MessageAuthorHeader(user: user)
                }

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
