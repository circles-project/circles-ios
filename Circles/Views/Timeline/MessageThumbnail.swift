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
    
    var thumbnail: Image {
        Image(uiImage: message.thumbnail ?? UIImage())
    }
    
    var body: some View {
        ZStack {
            thumbnail
                .resizable()
                .scaledToFill()
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
