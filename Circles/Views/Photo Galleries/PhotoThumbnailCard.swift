//  Copyright 2023 FUTO Holdings Inc
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
    @AppStorage("debugMode") var debugMode: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            if message.type == M_ROOM_MESSAGE {
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
            else {
                VStack {
                    let bgColor = colorScheme == .dark ? Color.black : Color.white
                    Image(systemName: "lock.rectangle")
                        .resizable()
                        .foregroundColor(Color.gray)
                        .scaledToFit()
                        .padding()
                    VStack {
                        Text("Decryption error")
                        if debugMode {
                            Text("Message id: \(message.id)")
                                .font(.footnote)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .background(
                        bgColor
                            .opacity(0.5)
                    )
                    .padding(.bottom, 2)
                }
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
