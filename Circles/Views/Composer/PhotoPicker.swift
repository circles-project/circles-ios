//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PhotoPicker.swift
//  Circles for iOS
//
//  Created by Charles Wright on 6/2/21.
//

import SwiftUI
import PhotosUI

// References:
// * Presenting PHPicker with SwiftUI - https://developer.apple.com/forums/thread/651743?answerId=617747022#617747022
// * https://www.appcoda.com/phpicker/
struct PhotoPicker: UIViewControllerRepresentable {
    //let configuration: PHPickerConfiguration
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        print("PICKER\tmakeUIViewController")
        // Hard-code the configuration.
        // We always just want one image
        // When we want something else, I guess we'll just make another class, like "VideoPicker" or something
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current

        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Use a Coordinator to act as your PHPickerViewControllerDelegate
    class Coordinator: PHPickerViewControllerDelegate {

        private let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            print("PICKER\tCoordinator.init()")
            self.parent = parent
        }

        private func getPhoto(from itemProvider: NSItemProvider) {
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { object, error in

                    if let error = error {
                        print("PICKER\tError: \(error.localizedDescription)")
                    }

                    if let image = object as? UIImage {
                        print("PICKER\tPhotoPicker got a photo")
                        DispatchQueue.main.async {
                            self.parent.selectedImage = image
                        }
                    }
                }

            } else {
                print("PICKER\tCan't load object from provider \(itemProvider.description)")
                print("PICKER\tDebug desc: \(itemProvider.debugDescription)")
            }
            
            print("PICKER\tSuggested name: \(itemProvider.suggestedName ?? "(none)")")
            print("PICKER\tRegistered type identifiers:")
            for typeId in itemProvider.registeredTypeIdentifiers {
                print("PICKER\t\t\(typeId)")
            }
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            //print(results)

            // We only asked for one image,
            // so if we got anything,
            // it should be in the first element of the array
            if let provider = results.first?.itemProvider {
                self.getPhoto(from: provider)
            } else {
                print("PICKER\tFailed to get provider, got nothing")
            }

            parent.isPresented = false // Set isPresented to false because picking has finished.
        }
    }
}
