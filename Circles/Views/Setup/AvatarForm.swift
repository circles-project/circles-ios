//
//  AvatarForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI
import PhotosUI

struct AvatarForm: View {
    var session: SetupSession

    @State var displayName = ""
    @State var avatarImage: UIImage?
    @State var showPicker = false
    @State var showCamera = false
    //@State var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var selectedItem: PhotosPickerItem?

    @State var pending = false

    let stage = "avatar"

    var avatar: Image {
        if let img = self.avatarImage {
            return Image(uiImage: img)
        } else {
            return Image(systemName: "person.crop.square")
        }
    }

    var body: some View {
        VStack {
            //let currentStage: SignupStage = .getAvatarImage

            Spacer()

            Text("Set up your profile")
                .font(.title)
                .fontWeight(.bold)

            avatar
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 160, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Choose a photo from my device's library", systemImage: "photo.fill")
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
            .padding()

            Button(action: {
                self.showCamera = true
            }) {
                Label("Take a new photo", systemImage: "camera")
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $avatarImage, sourceType: .camera)
            }
            .padding()
            
            TextField("First Last", text: $displayName, prompt: Text("Your name"))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .frame(width: 300)
                .padding()

            Spacer()

            AsyncButton(action: {
                if let image = avatarImage {
                    do {
                        try await session.setupProfile(name: displayName, avatar: image)
                    } catch {
                        
                    }
                }
            }) {
                Text("Next")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(avatarImage == nil || displayName.isEmpty)
            .padding()

        }
    }
}

/*
struct AvatarForm_Previews: PreviewProvider {
    static var previews: some View {
        AvatarForm()
    }
}
*/
