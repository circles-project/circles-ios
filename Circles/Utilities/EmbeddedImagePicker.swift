//
//  EmbeddedImagePicker.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 11/16/20.
//

import SwiftUI

import UIKit
import SwiftUI

// Inspired by https://www.appcoda.com/swiftui-camera-photo-library/

struct EmbeddedImagePicker: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    @Binding var selectedImage: UIImage?
    //@Environment(\.presentationMode) private var presentationMode
    @Binding var isEnabled: Bool
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var allowEditing = false
    
    var completion: (UIImage) -> Void = { _ in }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<EmbeddedImagePicker>) -> UIImagePickerController {

        let imagePicker = UIImagePickerController()
        //imagePicker.allowsEditing = false
        imagePicker.allowsEditing = allowEditing
        imagePicker.sourceType = sourceType
        
        imagePicker.delegate = context.coordinator

        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<EmbeddedImagePicker>) {

    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
     
        var parent: EmbeddedImagePicker
     
        init(_ parent: EmbeddedImagePicker) {
            self.parent = parent
        }
     
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
     
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.isEnabled = false
                // cvw: This is where we should call our "completion" closure to do whatever action we're supposed to do with the new image
                parent.completion(image)
            }
            else {
                // Just dismiss the view
                parent.isEnabled = false
                // Don't need to call the completion handler
            }
        }
    }
    
}



/*
struct EmbeddedImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker()
    }
}
 */
