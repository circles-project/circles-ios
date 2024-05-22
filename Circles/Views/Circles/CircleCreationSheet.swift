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
    
    var invitedCircleName: String? = nil
    
    @FocusState var inputFocused
    
    func create() async throws {
        // First create the Space for the circle
        let circleRoomId = try await container.createChild(name: circleName, type: M_SPACE, encrypted: false, avatar: avatarImage)
        
        guard let circleRoom = try await container.session.getRoom(roomId: circleRoomId, as: CircleSpace.self)
        else {
            print("Failed to get new circle Space room for roomId \(circleRoomId)")
            return
        }
        
        // Then create the "wall" timeline room
        let wallRoomId = try await circleRoom.createChild(name: circleName, type: ROOM_TYPE_CIRCLE, encrypted: true, avatar: avatarImage)

        // Invite our followers to join the room where we're going to post
        for user in users {
            try await container.session.inviteUser(roomId: wallRoomId, userId: user.userId)
        }
        
        if invitedCircleName != circleName {
            self.presentation.wrappedValue.dismiss()
        }
    }
    
    @ViewBuilder
    var buttonBar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            })
            {
                Text("Cancel")
            }
            
            Spacer()
        }
        .font(.subheadline)
    }
    
    var mockup: some View {
        HStack {
            let cardSize: CGFloat = 120
            
            Spacer()
            
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
                Text(circleName)
                    .lineLimit(3)
                    .font(.title2)
                    .fontWeight(.bold)
                
                let myUser = container.session.getUser(userId: container.session.creds.userId)
                Text(myUser.displayName ?? "\(myUser.userId)")
                    .font(.title2)
                    //.fontWeight(.bold)
                
                Text(myUser.userId.stringValue)
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    /// Use this only if the user does not have any circles. This function automatically creates a circle with the same name as the circle from the invitation
    var createInvitationCircle: some View {
        VStack { }
        .padding()
        .onAppear(perform: {
            guard let invitedCircleName else { return }
            circleName = invitedCircleName
            Task {
                try await create()
            }
        })
    }
    
    /// Use this when user want to create custom circle
    var createCustomCircle: some View {
        VStack {
            buttonBar
            
            mockup
                .padding()
            
            TextField("Circle name", text: $circleName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.words)
                .focused($inputFocused)
                .frame(maxWidth: 350)
                .onAppear {
                    self.inputFocused = true
                }

            Spacer()
            
            AsyncButton(action: {
                try await create()
            }) {
                Text("Create circle")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(circleName.isEmpty)
            
            Spacer()
        }
        .padding()
    }

    var body: some View {
        if invitedCircleName == nil {
            createCustomCircle
        } else {
            createInvitationCircle
        }
    }
}

/*
struct StreamCreationSheet_Previews: PreviewProvider {
    static var previews: some View {
        CircleCreationSheet(store: LegacyStore())
    }
}
*/
