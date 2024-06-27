//
//  AvatarForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI
import PhotosUI
import Matrix

struct SetupAvatarView: View {
    var matrix: Matrix.Session

    @Binding var displayName: String?
    @Binding var stage: SetupScreen.Stage
    @FocusState var inputFocused
    
    @State var newName: String = ""
    @State var avatarImage: UIImage?
    @State var showPicker = false
    @State var showCamera = false
    //@State var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var selectedItem: PhotosPickerItem?

    @State var pending = false

    var avatar: Image {
        if let img = self.avatarImage {
            return Image(uiImage: img)
        } else {
            return Image(systemName: SystemImages.personCropSquare.rawValue)
        }
    }

    var body: some View {
        let avatarSize: CGFloat = UIDevice.isPhoneSE ? 133 : 200
        ScrollView {
            //let currentStage: SignupStage = .getAvatarImage

            Spacer()

            Text("Set up your profile")
                .font(.title)
                .fontWeight(.bold)
                
            avatar
                .resizable()
                .scaledToFill()
                .frame(width: avatarSize, height: avatarSize, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .task {
                    // Check to see -- Does this user already have an avatar image?
                    let userId = matrix.creds.userId
                    if let image = try? await matrix.getAvatarImage(userId: userId) {
                        await MainActor.run {
                            self.avatarImage = image
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Menu {
                        Button(action: {
                            self.showPicker = true
                        }) {
                            Label("Choose a photo", systemImage: "photo.fill")

                        }
                        
                        Button(action: {
                            print("Showing camera")
                            self.showCamera = true
                        }) {
                            Label("Take a new photo", systemImage: "camera")
                        }
                    }
                    label: {
                        Image(systemName: SystemImages.pencilCircleFill.rawValue)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 30))
                            .foregroundColor(.accentColor)
                    }
                }
                .photosPicker(isPresented: $showPicker, selection: $selectedItem)
                .sheet(isPresented: $showCamera) {
                    ImagePicker(sourceType: .camera) { maybeImage in
                        if let image = maybeImage {
                            self.avatarImage = image
                        }
                    }
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data)
                        {
                            await MainActor.run {
                                self.avatarImage = img
                            }
                        }
                    }
                }
            
            Label("NOTE: Profile photos are not encrypted", systemImage: SystemImages.exclamationmarkTriangle.rawValue)
                .foregroundColor(.orange)

            TextField("First Last", text: $newName, prompt: Text("Your name"))
                .textContentType(.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
                .focused($inputFocused)
                .textInputAutocapitalization(.words)
                .frame(width: 300)
                .padding()
                .onAppear {
                    self.inputFocused = true
                }
                /*
                .task {
                    let userId = session.client.creds.userId
                    if let name = try? await session.client.getDisplayName(userId: userId) {
                        await MainActor.run {
                            self.displayName = name
                        }
                    }
                }
                */

            AsyncButton(action: {
                displayName = newName
                if let name = displayName {
                    try await matrix.setMyDisplayName(name)
                }
                if let image = avatarImage {
                    _ = try await matrix.setMyAvatarImage(image)
                }
                
                stage = .circlesIntro
            }) {
                Text("Next")
            }
            .buttonStyle(BigBlueButtonStyle())
            .disabled(newName.isEmpty)
            .padding()

            Spacer()
        }
        .scrollIndicators(.hidden)
    }
}

/*
struct AvatarForm_Previews: PreviewProvider {
    static var previews: some View {
        AvatarForm()
    }
}
*/
