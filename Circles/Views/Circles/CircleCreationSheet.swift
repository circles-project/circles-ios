//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleCreationSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/13/20.
//

import SwiftUI
import Matrix

struct CircleCreationSheet: View {
    @ObservedObject var container: ContainerRoom<CircleSpace>
    @Environment(\.presentationMode) var presentation
    
    @State private var circleName: String = ""
    @State private var rooms: Set<Matrix.Room> = []
    @State private var avatarImage: UIImage? = nil
    
    @State var users: [Matrix.User] = []
    @State var newestUserId: String = ""
    
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    
    var buttonBar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            })
            {
                Text("Cancel")
            }
            
            Spacer()
            
            AsyncButton(action: {
                
                // First create the Space for the circle
                let circleRoomId = try await container.createChildRoom(name: circleName, type: M_SPACE, encrypted: false, avatar: avatarImage)
                
                guard let circleRoom = try await container.session.getRoom(roomId: circleRoomId, as: CircleSpace.self)
                else {
                    print("Failed to get new circle Space room for roomId \(circleRoomId)")
                    return
                }
                
                // Then create the "wall" timeline room
                let wallRoomId = try await circleRoom.createChildRoom(name: circleName, type: ROOM_TYPE_CIRCLE, encrypted: true, avatar: avatarImage)

                // Invite our followers to join the room where we're going to post
                for user in users {
                    try await container.session.inviteUser(roomId: wallRoomId, userId: user.userId)
                }
                
                self.presentation.wrappedValue.dismiss()

            }) {
                Text("Create")
                    .fontWeight(.bold)
            }
            .disabled(circleName.isEmpty)
            //.padding()
        }
        .font(.subheadline)
    }
    
    var mockup: some View {
        HStack {
            ZStack {
                let cardSize: CGFloat = 120

                Circle()
                    .foregroundColor(Color.gray)
                    .opacity(0.80)
                    .frame(width: cardSize, height: cardSize)
                
                if let img = avatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardSize, height: cardSize)
                        //.clipped()
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 5)
                        .padding(5)
                }
            }
            
            VStack(alignment: .leading) {
                let myUser = container.session.getUser(userId: container.session.creds.userId)
                Text(myUser.displayName ?? "\(myUser.userId)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(circleName)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
    }

    var body: some View {
        VStack {
            buttonBar
                        
            Text("New Circle")
                .font(.headline)
                .fontWeight(.bold)
            
            mockup
                .padding()
            
            TextField("Circle name", text: $circleName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Spacer()
            
            VStack(alignment: .leading) {
                Text("Invite Followers")
                    .fontWeight(.bold)
                HStack {
                    TextField("User ID (e.g. @alice)", text: $newestUserId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                    
                    Button(action: {
                        guard let userId = UserId(newestUserId)
                        else {
                            self.alertTitle = "Invalid User ID"
                            self.alertMessage = "Circles user ID's should start with an @ and have a domain at the end, like @username:example.com"
                            self.showAlert = true
                            self.newestUserId = ""
                            print("CircleCreationSheet - ERROR:\t \(self.alertMessage)")
                            return
                        }
                        if container.joinedMembers.contains(userId) {
                            self.alertTitle = "\(userId) is already a member of this room"
                            self.alertMessage = ""
                            self.showAlert = true
                            print("CircleCreationSheet - ERROR:\t \(self.alertMessage)")
                            return
                        }
                        
                        print("CircleCreationSheet - INFO:\t Adding \(userId) to invite list")
                        let user = container.session.getUser(userId: userId)
                        users.append(user)
                        self.newestUserId = ""
                    }) {
                        Text("Add")
                    }
                }
                
                List($users, editActions: .delete) { $user in
                    MessageAuthorHeader(user: user)
                }
                
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }

        }
        .padding()
    }
}

/*
struct StreamCreationSheet_Previews: PreviewProvider {
    static var previews: some View {
        CircleCreationSheet(store: LegacyStore())
    }
}
*/
