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

struct MessageMediaThumbnail: View {
    @ObservedObject var message: Matrix.Message
    var aspectRatio: ContentMode = .fit
    var mediaViewWidth: CGFloat
    
    var thumbnail: Image {
        Image(uiImage: message.thumbnail ?? UIImage())
    }
    
    var body: some View {
        ZStack {
            let mediaHeightCalculation = MediaHeightCalculation(message: message, geoWidth: mediaViewWidth).height
            
            thumbnail
                .resizable()
                .aspectRatio(contentMode: aspectRatio)
//                .scaledToFill()
                .frame(width: CGFloat(mediaViewWidth), height: mediaHeightCalculation)
                .foregroundColor(.gray)
        }
    }
}

@MainActor
class MediaHeightCalculation: ObservableObject {
    private var message: Matrix.Message
    private var mediaViewWidth: Double
    private var customRatio: Double = 0.0
    @Published var height = 0.0
    @AppStorage("mediaViewHeight") private var mediaViewHeight: Double = 0
    
    init(message: Matrix.Message,
         geoWidth: CGFloat) {
        self.message = message
        self.mediaViewWidth = geoWidth
        
        calculateMediaHeight()
    }
    
    private func calculateMediaHeight() {
        if let img = message.thumbnail {
            let imageRatio = img.size.width / img.size.height
            let minAllowedImageHeight: CGFloat = 140.0
            let maxAllowedImageHeight: CGFloat = mediaViewHeight - 180 // 180 = 90 tabbar and navigationbar; 60 header of the card; 30 extra space to show bottom;
            
            switch imageRatio {
            case 0...0.5:
                customRatio = 0.5
            case 0.5...3:
                customRatio = imageRatio
            default:
                customRatio = 3
            }
            
            let customImageHeight = mediaViewWidth / customRatio
            
            switch customImageHeight {
            case 0...minAllowedImageHeight:
                height = minAllowedImageHeight
            case minAllowedImageHeight...maxAllowedImageHeight:
                height = customImageHeight
            default:
                height = maxAllowedImageHeight
            }
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
