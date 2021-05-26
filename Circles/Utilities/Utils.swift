//
//  Utils.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/28/20.
//

// swiftlint:disable identifier_name

import Foundation
import UIKit

func downscale_image(from image: UIImage, to maxSize: CGSize) -> UIImage? {
    let height = image.size.height
    let width = image.size.width
    let MAX_HEIGHT = maxSize.height
    let MAX_WIDTH = maxSize.width
    print("DOWNSCALE\t h = \(height)\t w = \(width)")
    print("DOWNSCALE\t max h = \(MAX_HEIGHT)\t max w = \(MAX_WIDTH)")
    if height > MAX_HEIGHT || width > MAX_WIDTH {
        let aspectRatio = image.size.width / image.size.height
        print("DOWNSCALE\tAspect ratio = \(aspectRatio)")
        let scale = aspectRatio > 1
            ? MAX_WIDTH / image.size.width
            : MAX_HEIGHT / image.size.height
        print("DOWNSCALE\tScale = \(scale)")
        let newSize = CGSize(width: scale*image.size.width, height: scale*image.size.height)
        print("DOWNSCALE\tNew size = \(newSize)")
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    return image
}
