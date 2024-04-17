//
//  VideoThumbnailCard.swift
//  Circles
//
//  Created by Charles Wright on 4/17/24.
//

import SwiftUI
import Matrix

struct VideoThumbnailCard: View {
    @ObservedObject var message: Matrix.Message
    var height: CGFloat
    var width: CGFloat
    @State var playVideo: Bool = false
    
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

                    
                    Image(systemName: "play.circle")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                        .frame(width: width/2, height: height/2)
                        .onTapGesture {
                            self.playVideo = true
                        }
                        .fullScreenCover(isPresented: $playVideo) {
                            VideoDetailView(message: message)
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
