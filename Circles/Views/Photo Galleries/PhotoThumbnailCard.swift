//
//  PhotoThumbnailCard.swift
//  Circles
//
//  Created by Charles Wright on 6/15/23.
//

import SwiftUI
import Matrix

struct PhotoThumbnailCard: View {
    @ObservedObject var message: Matrix.Message
    var height: CGFloat
    var width: CGFloat
    @State var showFullScreen: Bool = false

    var body: some View {
        ZStack {
            if let img = message.thumbnail {
                Image(uiImage: img)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height, alignment: .center)
                    .clipped()
                    .onTapGesture {
                        self.showFullScreen = true
                    }
                    .fullScreenCover(isPresented: $showFullScreen) {
                        PhotoDetailView(message: message)
                    }
            } else {
                Color.gray
                    .onAppear {
                        let task = Task {
                            try await message.fetchThumbnail()
                        }
                    }
                ProgressView()
            }
        }
    }
}

/*
struct PhotoThumbnailCard_Previews: PreviewProvider {
    static var previews: some View {
        PhotoThumbnailCard()
    }
}
*/
