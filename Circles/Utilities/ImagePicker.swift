//
//  ImagePicker.swift
//  Circles for iOS
//
//  Created by Charles Wright on 7/22/20.
//

import UIKit
import SwiftUI

// Inspired by https://www.appcoda.com/swiftui-camera-photo-library/

struct ImagePicker: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var allowEditing = false
    
    var completion: (UIImage?) -> Void = { _ in }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {

        let imagePicker = UIImagePickerController()
        //imagePicker.allowsEditing = false
        imagePicker.allowsEditing = allowEditing
        imagePicker.sourceType = sourceType
        
        imagePicker.delegate = context.coordinator

        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
     
        var parent: ImagePicker
     
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
     
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
     
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.presentationMode.wrappedValue.dismiss()

                // cvw: This is where we should call our "completion" closure to do whatever action we're supposed to do with the new image
                parent.completion(image)
            }
            else {
                // Just dismiss the view
                parent.presentationMode.wrappedValue.dismiss()
                // Don't need to call the completion handler
                parent.completion(nil)
            }
        }
    }
    
}



/*
struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker()
    }
}
 */
