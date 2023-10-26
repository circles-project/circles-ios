//
//  QR.swift
//  Circles
//
//  Created by Charles Wright on 10/26/23.
//

import Foundation
import UIKit
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins

// A QR code of the room id
func qrCode(url: URL) -> UIImage? {
    guard let data = url.absoluteString.data(using: .ascii)
    else {
        print("Failed to generate QR code: Couldn't get roomId as ASCII data")
        return nil
    }
    
    // Use the built-in CoreImage filter to create our QR code
    // https://developer.apple.com/documentation/coreimage/ciqrcodegenerator
    let filter = CIFilter.qrCodeGenerator()
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("Q", forKey: "inputCorrectionLevel")  // 25%
    guard let result = filter.outputImage
    else {
        print("Failed to generate QR code: Couldn't get CIFilter output image")
        return nil
    }
    
    // Scale up the QR code by a factor of 10x
    let transform = CGAffineTransform(scaleX: 10, y: 10)
    let transformedImage = result.transformed(by: transform)
    
    // For whatever reason, we MUST convert to a CGImage here, using the CIContext.
    // If we do not do this (eg by trying to create a UIImage directly from the CIImage),
    // then we get nothing but a blank square for our QR code. :(
    let context = CIContext()
    guard let cgImg = context.createCGImage(transformedImage, from: transformedImage.extent)
    else {
        print("Failed to generate QR code: Failed to create CGImage from transformed image")
        return nil
    }
    
    let img = UIImage(cgImage: cgImg)
    print("QR code image is \(img.size.height) x \(img.size.width)")
    return img
}
