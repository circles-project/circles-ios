//
//  AvatarForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI

struct AvatarForm: View {
    var matrix: MatrixInterface
    @Binding var pseudoFlow: UiaaAuthFlow

    @State var avatarImage: UIImage?
    @State var showPicker = false
    @State var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary

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

            Text("Upload a profile photo")
                .font(.title)
                .fontWeight(.bold)

            avatar
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 160, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: {
                self.showPicker = true
                self.pickerSourceType = .photoLibrary
            }) {
                Label("Choose a photo from my device's library", systemImage: "photo.fill")
            }
            .padding()

            Button(action: {
                self.showPicker = true
                self.pickerSourceType = .camera
            }) {
                Label("Take a new photo", systemImage: "camera")
            }
            .padding()

            Spacer()

            Button(action: {
                // Upload the image and set it as our avatar
                if let img = self.avatarImage {
                    self.pending = true
                    self.matrix.setAvatarImage(image: img) { response in
                        if response.isSuccess {
                            //self.stage = next[currentStage]!
                            pseudoFlow.pop(stage: self.stage)
                        }
                        self.pending = false
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
            .disabled(pending)

        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(selectedImage: $avatarImage,
                        sourceType: self.pickerSourceType)
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
