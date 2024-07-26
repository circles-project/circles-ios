//
//  ChatCreationSheet.swift
//  Circles
//
//  Created by Charles Wright on 7/26/24.
//

import SwiftUI
import PhotosUI
import Matrix

struct ChatCreationSheet: View {
    @ObservedObject var session: Matrix.Session
    @Environment(\.presentationMode) var presentation
    
    @State var roomName: String = ""
    @State var roomTopic: String = ""
    
    @State var newestUserId: String = ""
    @State var users: [Matrix.User] = []
    
    @State var headerImage: UIImage? = nil
    @State var showPicker = false
    @State var selectedItem: PhotosPickerItem?
    
    @State var defaultPowerLevel = PowerLevel(power: 0)
    
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    
    @FocusState var inputFocused
    
    func create() async throws {
        let powerLevels = RoomPowerLevelsContent(invite: 50, usersDefault: defaultPowerLevel.power)
        guard let roomId = try? await session.createRoom(name: self.roomName,
                                                         type: nil,
                                                         encrypted: true,
                                                         invite: self.users.map { $0.userId },
                                                         powerLevelContentOverride: powerLevels),
              let room = try await session.getRoom(roomId: roomId)
        else {
            // Set error message
            return
        }
        
        if let avatar = self.headerImage {
            do {
                try await room.setAvatarImage(image: avatar)
            } catch {
                // Move on with life.. we can fix the avatar later
            }
        }
        
        if !self.roomTopic.isEmpty {
            do {
                try await room.setTopic(newTopic: self.roomTopic)
            } catch {
                // Move on with life.. we can fix the topic later
            }
        }
        
        self.presentation.wrappedValue.dismiss()
    }
    
    @ViewBuilder
    var buttonbar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            })
            {
                Text("Cancel")
            }
            
            Spacer()
        }
    }
    
    var body: some View {
        VStack {
            buttonbar
            let frameWidth = 300.0
            let frameHeight = 200.0
      
            ZStack {
                if let img = self.headerImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: frameWidth, maxHeight: frameHeight)

                } else {
                    Color.gray
                        .frame(width: frameWidth, height: frameHeight)
                }

                VStack {
                    Text(self.roomName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.white)
                        .shadow(color: Color.black, radius: 3.0)
                        .minimumScaleFactor(0.8)
                        .padding()
                    
                    Text(self.roomTopic)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.white)
                        .shadow(color: Color.black, radius: 3.0)
                        .padding(.horizontal)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: frameWidth, maxHeight: frameHeight)
            .overlay(alignment: .bottomTrailing) {
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: SystemImages.pencilCircleFill.rawValue)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)

            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data)
                    {
                        await MainActor.run {
                            self.headerImage = img
                        }
                    }
                }
            }
            
            TextField("Chat name", text: $roomName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.words)
                .focused($inputFocused)
                .padding(.horizontal)
                .onAppear {
                    self.inputFocused = true
                }
            
            HStack {
                Text("Default user role")
                Spacer()
                Picker("User permissions", selection: $defaultPowerLevel) {
                    ForEach(CIRCLES_POWER_LEVELS) { level in
                        Text(level.description)
                            .tag(level)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()

            AsyncButton(action: {
                try await create()
            })
            {
                Text("Create chat")
            }
            .buttonStyle(BigRoundedButtonStyle())
            .disabled(roomName.isEmpty)
            
            Spacer()

        }
        .padding()
    }
    
}
