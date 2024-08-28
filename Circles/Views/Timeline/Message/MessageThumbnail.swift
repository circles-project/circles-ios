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
    let maxHeight = 0.55 * UIScreen.main.bounds.height

    var thumbnail: Image {
        Image(uiImage: message.thumbnail ?? UIImage())
    }
    
    
    var body: some View {
        ZStack {
            /*
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        size.width = max(size.width, geometry.size.width)
                        size.height = max(size.height, geometry.size.height)
                    }
            }
            */

            thumbnail
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.gray)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(maxHeight: maxHeight)
                .border(Color.red)

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
