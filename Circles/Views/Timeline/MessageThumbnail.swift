//
//  MessageThumbnail.swift
//  Circles
//
//  Created by Charles Wright on 8/13/23.
//

import SwiftUI
import Matrix

struct MessageThumbnail: View {
    @ObservedObject var message: Matrix.Message
    var aspectRatio: ContentMode = .fit
    
    var thumbnail: Image {
        Image(uiImage: message.thumbnail ?? UIImage())
    }
    
    var body: some View {
        ZStack {
            thumbnail
                .resizable()
                .aspectRatio(contentMode: aspectRatio)
                //.clipShape(RoundedRectangle(cornerRadius: 6))
                .foregroundColor(.gray)
        }
    }
}

struct MediaSize {
    let height: Double
    let width: Double
    let maxMediaHeight: Double
}

struct MessageMediaThumbnail: View {
    @ObservedObject var message: Matrix.Message
    var aspectRatio: ContentMode = .fit
    var mediaViewWidth: CGFloat
    
    var thumbnail: Image {
        Image(uiImage: message.thumbnail ?? UIImage())
    }
    
    private func calculateAllowedSizeFor(_ nativeImage: Matrix.NativeImage?) -> MediaSize {
        @AppStorage("mediaViewHeight") var mediaViewHeight: Double = 0
        var customRatio: Double = 0.0
        
        if let img = nativeImage {
            let imageRatio = img.size.width / img.size.height
            let maxAllowedImageHeight: CGFloat = mediaViewHeight - 180 // 180 = 90 tabbar and navigationbar; 60 header of the card; 30 extra space to show bottom;
            
            switch imageRatio {
            case 0...0.5: customRatio = 0.5
            case 0.5...3: customRatio = imageRatio
            default:      customRatio = 3
            }
            
            return MediaSize(height: img.size.height * customRatio,
                             width: img.size.width * customRatio,
                             maxMediaHeight: maxAllowedImageHeight)
        }
        return MediaSize(height: 0, width: 0, maxMediaHeight: 0)
    }
    
    private func getMediaSize(_ media: MediaSize) -> (width: Double, height: Double) {
        var width = 0.0
        var height = 0.0
        
        let mediaWidth = media.width
        let mediaHeight = media.height
        let maxMediaHeight = media.maxMediaHeight
        
        if mediaWidth > mediaViewWidth {
            let ratio = mediaViewWidth / mediaWidth
            if mediaHeight * ratio > maxMediaHeight {
                height = maxMediaHeight
            } else {
                height = mediaHeight * ratio
            }
            width = mediaViewWidth - 20
        } else {
            if mediaHeight > maxMediaHeight {
                let ratio = maxMediaHeight / mediaHeight
                height = maxMediaHeight
                width = mediaWidth * ratio
            } else {
                height = mediaHeight
                width = mediaWidth
            }
        }
        
        return (width: width, height: height)
    }
    
    var body: some View {
        ZStack {
            let allowedMediaSize = calculateAllowedSizeFor(message.thumbnail) //MediaSizeCalculation(nativeImage: message.thumbnail)
            
            let mediaSize = getMediaSize(allowedMediaSize)
            thumbnail
                .resizable()
                .frame(width: mediaSize.width, height: mediaSize.height)
                .aspectRatio(contentMode: aspectRatio)
                .foregroundColor(.gray)
        }
    }
}

/*
struct MessageThumbnail_Previews: PreviewProvider {
    static var previews: some View {
        MessageThumbnail()
    }
}
*/
