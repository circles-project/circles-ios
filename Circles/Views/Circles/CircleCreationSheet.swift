//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleCreationSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/13/20.
//

import SwiftUI
import PhotosUI
import Matrix

struct CircleCreationSheet: View {
    @ObservedObject var container: ContainerRoom<CircleSpace>
    @Environment(\.presentationMode) var presentation
    
    @State private var circleName: String = ""
    @State private var rooms: Set<Matrix.Room> = []
    @State private var avatarImage: UIImage? = nil
    @State private var showPicker = false
    @State private var item: PhotosPickerItem?
    
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
            let cardSize: CGFloat = 90
            
            ZStack {
                if let img = avatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray
                }
            }
            .frame(width: cardSize, height: cardSize)
            .clipShape(Circle())
            //.overlay(Circle().stroke(Color.gray, lineWidth: 2))
            .overlay(alignment: .bottomTrailing) {
                PhotosPicker(selection: $item, matching: .images) {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
            }
            .shadow(radius: 5)
            .padding(.horizontal, 5)
            .onChange(of: item) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        let img = UIImage(data: data)
                        await MainActor.run {
                            self.avatarImage = img
                        }
                    }
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
            
            mockup
                .padding()
            
            TextField("Circle name", text: $circleName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Spacer()
            
            VStack(alignment: .leading) {
                Text("Invite Followers")
                    .fontWeight(.bold)
 
                UsersToInviteView(session: container.session, users: $users)
                
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
