//
//  ImageSaver.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/11/20.
//

import Foundation
import UIKit

// https://www.hackingwithswift.com/books/ios-swiftui/how-to-save-images-to-the-users-photo-library
// https://www.hackingwithswift.com/read/13/5/saving-to-the-ios-photo-library

class ImageSaver: NSObject {
    @IBAction func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error: Save failed")
        } else {
            print("Save finished!")
        }
    }
}
