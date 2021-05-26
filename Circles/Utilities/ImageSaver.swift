//
//  ImageSaver.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/11/20.
//

import Foundation
import UIKit

// https://www.hackingwithswift.com/books/ios-swiftui/how-to-save-images-to-the-users-photo-library

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }

    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("Save finished!")
    }
}
