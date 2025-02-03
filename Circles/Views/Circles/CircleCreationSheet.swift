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
    @ObservedObject var container: TimelineSpace
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
        
        let session = container.session
        
        // First create the "wall" timeline room
        let roomId = try await session.createRoom(name: circleName, type: ROOM_TYPE_CIRCLE, encrypted: true)
        if let image = avatarImage {
            try await session.setAvatarImage(roomId: roomId, image: image)
        }
        
        // Add the wall as a child room of the container
        try await container.addChild(roomId)
        
        guard let _ = try await session.getRoom(roomId: roomId, as: Matrix.Room.self)
        else {
            print("Failed to get new circle timeline room for roomId \(roomId)")
            return
        }
        
        // Invite our followers to join the room where we're going to post
        for user in users {
            try await session.inviteUser(roomId: roomId, userId: user.userId)
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
                    Image(systemName: SystemImages.pencilCircleFill.rawValue)
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
            }
            .buttonStyle(BigRoundedButtonStyle())
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
