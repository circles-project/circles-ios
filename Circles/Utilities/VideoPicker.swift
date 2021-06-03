//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  VideoPicker.swift
//  Circles for iOS
//
//  Created by Charles Wright on 6/2/21.
//

import SwiftUI
import PhotosUI

// References:
// * Presenting PHPicker with SwiftUI - https://developer.apple.com/forums/thread/651743?answerId=617747022#617747022
// * https://www.appcoda.com/phpicker/
struct VideoPicker: UIViewControllerRepresentable {
    //let configuration: PHPickerConfiguration
    @Binding var isPresented: Bool
    @Binding var videoURL: URL?
    @Binding var thumbnail: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Hard-code the configuration.
        // We always just want one image
        // When we want something else, I guess we'll just make another class, like "VideoPicker" or something
        var config = PHPickerConfiguration()
        config.filter = .videos
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

        private let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        private func getVideo(from itemProvider: NSItemProvider, typeIdentifier: String) {
            itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                    if let error = error {
                        print(error.localizedDescription)
                    }

                    guard let url = url else { return }

                    DispatchQueue.main.async {
                        self.parent.videoURL = url
                    }
            }
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            //print(results)

            // We only asked for one image,
            // so if we got anything,
            // it should be in the first element of the array
            guard let result = results.first,
                  let typeIdentifier = result.itemProvider.registeredTypeIdentifiers.first,
                  let utType = UTType(typeIdentifier),
                  utType.conforms(to: .movie)
            else {
                parent.isPresented = false // Set isPresented to false because picking has finished.
                return
            }

            // Getting the actual video is comparatively simple
            // We go ahead and grab this before we attempt the thumbnail
            // That way, if the thumbnail fails, then at least we still get the actual video itself
            self.getVideo(from: result.itemProvider, typeIdentifier: typeIdentifier)

            // The rest of this craziness is just to get the damn *thumbnail*
            guard let identifier = result.assetIdentifier
            else {
                parent.isPresented = false
                return
            }

            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            let thumbnailRes = CGSize.init(width: 640, height: 480)
            fetchResult.enumerateObjects() { (asset, index, stop) -> Void in
                PHImageManager
                    .default()
                    .requestImage(for: asset,
                                  targetSize: thumbnailRes,
                                  contentMode: .aspectFill,
                                  options: nil
                    ) { (image: UIImage?, _: [AnyHashable : Any]?) in
                        if let image = image {
                            self.parent.thumbnail = image
                        }
                    }
            }

            parent.isPresented = false // Set isPresented to false because picking has finished.
        }
    }
}
