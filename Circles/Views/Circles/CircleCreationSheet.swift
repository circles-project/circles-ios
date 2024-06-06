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
    
    @FocusState var inputFocused
    
    func create() async throws {
        // NOTE: We must be careful here.
        //       We only want the new circle to appear as one of our circles IFF it is fully-formed with a valid "wall" room.
        //       Therefore we must create the "wall" room first, then create the space for the circle, then add the wall to the circle.
        //       Only then can we add the circle to our container as one of our active circles.
        
        // First create the "wall" timeline room
        let wallRoomId = try await container.session.createRoom(name: circleName, type: ROOM_TYPE_CIRCLE, encrypted: true)
        if let image = avatarImage {
            try await container.session.setAvatarImage(roomId: wallRoomId, image: image)
        }
        
        // Then create the Space for the circle
        let circleRoomId = try await container.session.createRoom(name: circleName, type: M_SPACE, encrypted: false)
        if let image = avatarImage {
            try await container.session.setAvatarImage(roomId: circleRoomId, image: image)
        }
        
        // Add the wall as a child room of the circle
        try await container.session.addSpaceChild(wallRoomId, to: circleRoomId)
        // Add the circle as a child room of the container
        try await container.addChild(circleRoomId)
        
        guard let circleRoom = try await container.session.getRoom(roomId: circleRoomId, as: CircleSpace.self)
        else {
            print("Failed to get new circle Space room for roomId \(circleRoomId)")
            return
        }
        
        // Invite our followers to join the room where we're going to post
        for user in users {
            try await container.session.inviteUser(roomId: wallRoomId, userId: user.userId)
        }
        
        self.presentation.wrappedValue.dismiss()
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
                    .minimumScaleFactor(0.8)
                
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

    var body: some View {
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
}

/*
struct StreamCreationSheet_Previews: PreviewProvider {
    static var previews: some View {
        CircleCreationSheet(store: LegacyStore())
    }
}
*/
